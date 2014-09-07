package Minion;

use strict;
use 5.008_005;
use Carp;
use Hash::Util qw( lock_keys );
use List::MoreUtils qw( all );
use Module::Runtime qw( require_module );
use Package::Stash;
use Sub::Name;

use Exception::Class (
    'Minion::Error::InterfaceMismatch',
    'Minion::Error::MethodDeclaration',
    'Minion::Error::RoleConflict',
);

our $VERSION = 0.000_001;

my $Class_count = 0;

sub minionize {
    my (undef, $spec) = @_;

    my $cls_stash;
    if ( ! $spec ) {
        my $caller_pkg = (caller)[0];
        $cls_stash = Package::Stash->new($caller_pkg);
        $spec  = $cls_stash->get_symbol('%__Meta');
        $spec->{name} = $caller_pkg;
    }
    $spec->{name} ||= "Minion::Class_${\ ++$Class_count }";
    $cls_stash    ||= Package::Stash->new($spec->{name});
    
    my $obj_stash;

    if ( $spec->{implementation} && ! ref $spec->{implementation} ) {
        my $pkg = $spec->{implementation};
        $pkg ne $spec->{name}
          or confess "$spec->{name} cannot be its own implementation.";
        my $stash = _get_stash($pkg);

        my $meta = $stash->get_symbol('%__Meta');
        $spec->{implementation} = { 
            package => $pkg, 
            methods => $stash->get_all_symbols('CODE'),
            roles   => $meta->{roles},
            has     => {
                %{ $meta->{has} || { } },
            },
        };
        my $is_semiprivate = _interface($meta, 'semiprivate');

        foreach my $sub ( keys %{ $spec->{implementation}{methods} } ) {
            if ( $is_semiprivate->{$sub} ) {
                $spec->{implementation}{semiprivate}{$sub} = delete $spec->{implementation}{methods}{$sub};
            }
        }
    }
    $obj_stash = Package::Stash->new("$spec->{name}::__Minion");
    
    my $class_meta = $cls_stash->get_symbol('%__Meta') || {};
    
    for my $name ( keys %{ $class_meta->{requires} } ) {
        my $meta = $class_meta->{requires}{$name};
        if ( $meta->{attribute} ) {
            my $attr_name = $meta->{attribute} == 1 ? $name : $meta->{attribute};
            $spec->{implementation}{has}{$name} = $meta;
        }
    }
    _compose_roles($spec);

    my $private_stash = Package::Stash->new("$spec->{name}::__Private");
    $cls_stash->add_symbol('$__Obj_pkg', $obj_stash->name);
    $cls_stash->add_symbol('$__Private_pkg', $private_stash->name);
    $cls_stash->add_symbol('%__Meta', $spec) if @_ > 0;
    
    _add_class_methods($spec, $cls_stash);
    _add_methods($spec, $obj_stash, $private_stash);
    _check_role_requirements($spec);
    _check_interface($spec);
    return $spec->{name};
}

sub _compose_roles {
    my ($spec, $roles, $from_role) = @_;
    
    if ( ! $roles ) {
        $roles = $spec->{roles};
        
        # An implementation may be needed to resolve
        # a role conflict, so implementations and roles
        # are not mutually exclusive
        if ( $spec->{implementation}{roles} ) {
            push @{ $roles }, @{ $spec->{implementation}{roles} };
        }
        
    }
    
    $from_role ||= {};
    
    for my $role ( @{ $roles } ) {
        
        if ( $spec->{composed_role}{$role} ) {
            confess "Cannot compose role '$role' twice";
        }
        else {
            $spec->{composed_role}{$role}++;
        }
        
        my ($meta, $method) = _load_role($role);
        $spec->{required}{$role} = $meta->{requires};
        _compose_roles($spec, $meta->{roles} || [], $from_role);
        
        _add_role_items($spec, $from_role, $role, $meta->{has}, 'has');
        _add_role_methods($spec, $from_role, $role, $meta, $method);
    }
}

sub _load_role {
    my ($role) = @_;
    
    my $stash  = _get_stash($role);
    my $meta   = $stash->get_symbol('%__Meta');
    $meta->{role}
      or confess "$role is not a role";
    
    my $method = $stash->get_all_symbols('CODE');
    return ($meta, $method);
}

sub _check_role_requirements {
    my ($spec) = @_;

    foreach my $role ( keys %{ $spec->{required} } ) {

        my $required = $spec->{required}{$role};

        foreach my $name ( @{ $required->{methods} } ) {

            unless (   defined $spec->{implementation}{methods}{$name}
                    || defined $spec->{implementation}{semiprivate}{$name}
                   ) {
                confess "Method '$name', required by role $role, is not implemented.";
            }
        }
        foreach my $name ( @{ $required->{attributes} } ) {
            defined $spec->{implementation}{has}{$name}
              or confess "Attribute '$name', required by role $role, is not defined.";
        }
    }
}

sub _check_interface {
    my ($spec) = @_;
    my $count = 0;
    foreach my $method ( @{ $spec->{interface} } ) {
        defined $spec->{implementation}{methods}{$method}
          or confess "Interface method '$method' is not implemented.";
        ++$count;
    }
    $count > 0 or confess "Cannot have an empty interface.";
}

sub _get_stash {
    my $pkg = shift;

    my $stash = Package::Stash->new($pkg); # allow for inlined pkg

    if ( ! $stash->has_symbol('%__Meta') ) {
        require_module($pkg);
        $stash = Package::Stash->new($pkg);
    }
    if ( ! $stash->has_symbol('%__Meta') ) {
        confess "Package $pkg has no %__Meta";
    }
    return $stash;
}

sub _add_role_items {
    my ($spec, $from_role, $role, $item, $type) = @_;

    for my $name ( keys %$item ) {
        if (my $other_role = $from_role->{$name}) {
            _raise_role_conflict($name, $role, $other_role);
        }
        else{
            if ( ! $spec->{implementation}{$type}{$name} ) {
                $spec->{implementation}{$type}{$name} = $item->{$name};
                $from_role->{$name} = $role;
            }
        }            
    }
}

sub _add_role_methods {
    my ($spec, $from_role, $role, $role_meta, $code_for) = @_;

    my $in_class_interface = _interface($spec);
    my $in_role_interface  = _interface($role_meta);
    my $is_semiprivate     = _interface($role_meta, 'semiprivate');

    all { defined $in_class_interface->{$_} } keys %$in_role_interface
      or Minion::Error::InterfaceMismatch->throw(
        error => "Interfaces do not match: Class => $spec->{name}, Role => $role"
      );

    for my $name ( keys %$code_for ) {
        if (    $in_role_interface->{$name}
             || $in_class_interface->{$name}
           ) {
            if (my $other_role = $from_role->{method}{$name}) {
                _raise_role_conflict($name, $role, $other_role);
            }
            if ( ! $spec->{implementation}{methods}{$name} ) {
                $spec->{implementation}{methods}{$name} = $code_for->{$name};
                $from_role->{method}{$name} = $role;
            }
        }
        elsif ( $is_semiprivate->{$name} ) {
            if (my $other_role = $from_role->{semiprivate}{$name}) {
                _raise_role_conflict($name, $role, $other_role);
            }
            if ( ! $spec->{implementation}{semiprivate}{$name} ) {
                $spec->{implementation}{semiprivate}{$name} = $code_for->{$name};
                $from_role->{semiprivate}{$name} = $role;
            }
        }
    }
}

sub _raise_role_conflict {
    my ($name, $role, $other_role) = @_;

    Minion::Error::RoleConflict->throw(
        error => "Cannot have '$name' in both $role and $other_role"
    );
}

sub _get_object_maker {

    sub {
        my $class = shift;
        
        my $stash = Package::Stash->new($class);
        my %obj = ( '!' => ${ $stash->get_symbol('$__Private_pkg') } );

        my $spec = $stash->get_symbol('%__Meta');
        
        while ( my ($attr, $meta) = each %{ $spec->{implementation}{has} } ) {
            $obj{"__$attr"} = ref $meta->{default} eq 'CODE'
              ? $meta->{default}->()
              : $meta->{default};
        }
        
        bless \ %obj => ${ $stash->get_symbol('$__Obj_pkg') };            
        lock_keys(%obj);
        return \ %obj;
    };
}

sub _add_class_methods {
    my ($spec, $stash) = @_;

    $spec->{class_methods} ||= $stash->get_all_symbols('CODE');
    _add_default_constructor($spec);
    $spec->{class_methods}{__new__} = _get_object_maker();
    
    $spec->{class_methods}{__build__} = sub {
        my (undef, $obj, $arg) = @_;
        if ( my $builder = $obj->{'!'}->can('BUILD') ) {
            $builder->($obj->{'!'}, $obj, $arg);
        }
    };
    
    $spec->{class_methods}{__assert__} = sub {
        my (undef, $slot, $val) = @_;
        
        return unless exists $spec->{requires}{$slot};
        
        my $meta = $spec->{requires}{$slot};
        
        for my $desc ( keys %{ $meta->{assert} || {} } ) {
            my $code = $meta->{assert}{$desc};
            $code->($val)
              or confess "Attribute '$slot' is not $desc";
        }
    };
    
    foreach my $sub ( keys %{ $spec->{class_methods} } ) {
        $stash->add_symbol("&$sub", $spec->{class_methods}{$sub});
        subname "$spec->{name}::$sub", $spec->{class_methods}{$sub};
    }
}

sub _add_default_constructor {
    my ($spec) = @_;
    
    if ( ! exists $spec->{class_methods}{new} ) {
        $spec->{class_methods}{new} = sub {
            my $class = shift;
            my ($arg);

            if ( scalar @_ == 1 ) {
                $arg = shift;
            }
            elsif ( scalar @_ > 1 ) {
                $arg = { @_ };
            }
            my $obj = $class->__new__;
            for my $name ( keys %{ $spec->{requires} } ) {
                defined $arg->{$name}
                  or confess "Param '$name' was not provided.";
                  
                $class->__assert__($name, $arg->{$name});
                my $meta = $spec->{requires}{$name};
                if ( $meta->{attribute} ) {
                    $obj->{"__$name"} = $arg->{$name};
                }
            }
            
            $class->__build__($obj, $arg);
            return $obj;
        };
        
        if (exists $spec->{class_methods}{BUILDARGS}) {
            my $build_args = $spec->{class_methods}{BUILDARGS};
            my $prev_new = $spec->{class_methods}{new};
            
            $spec->{class_methods}{new} = sub {
                my $class = shift;
                $prev_new->($class, $build_args->($class, @_));
            };
        }
    }
}

sub _add_methods {
    my ($spec, $stash, $private_stash) = @_;

    my $in_interface = _interface($spec);

    $spec->{implementation}{semiprivate}{ASSERT} = sub {
        my (undef, $slot, $val) = @_;
        
        return unless exists $spec->{implementation}{has}{$slot};
        
        my $meta = $spec->{implementation}{has}{$slot};
        
        for my $desc ( keys %{ $meta->{assert} || {} } ) {
            my $code = $meta->{assert}{$desc};
            $code->($val)
              or confess "Attribute '$slot' is not $desc";
        }
    };
    $spec->{implementation}{methods}{DOES} = sub {
        my (undef, $r) = @_;
        $spec->{name} eq $r || $spec->{composed_role}{$r};
    };
    
    while ( my ($name, $meta) = each %{ $spec->{implementation}{has} } ) {

        if ( $meta->{reader} && $in_interface->{$name} ) {
            my $name = $meta->{reader} == 1 ? $name : $meta->{reader};
            $spec->{implementation}{methods}{$name} = sub { $_[0]->{"__$name"} };
        }
        _add_delegates($spec, $meta, $name);
    }

    while ( my ($name, $sub) = each %{ $spec->{implementation}{methods} } ) {
        $stash->add_symbol("&$name", subname $stash->name."::$name" => $sub);
    }
    while ( my ($name, $sub) = each %{ $spec->{implementation}{semiprivate} } ) {
        $private_stash->add_symbol("&$name", subname $private_stash->name."::$name" => $sub);
    }
}

sub _add_delegates {
    my ($spec, $meta, $name) = @_;

    if ( $meta->{handles} ) {
        my $method;
        my $target_method = {};
        if ( ref $meta->{handles} eq 'ARRAY' ) {
            $method = { map { $_ => 1 } @{ $meta->{handles} } };
        }
        elsif( ref $meta->{handles} eq 'HASH' ) {
            $method = $meta->{handles};
            $target_method = $method;
        }
        elsif( ! ref $meta->{handles} ) {
            (undef, $method) = _load_role($meta->{handles});
        }
        my $in_interface = _interface($spec);
        
        foreach my $meth ( keys %{ $method } ) {
            if ( defined $spec->{implementation}{methods}{$meth} ) {
                confess "Cannot override implemented method '$meth' with a delegated method";
            }
            else {
                my $target = $target_method->{$meth} || $meth;
                $spec->{implementation}{methods}{$meth} =
                  $in_interface->{$meth}
                    ? sub { shift->{"__$name"}->$target(@_) }
                    : sub { shift; shift->{"__$name"}->$target(@_) };
            }
        }
    }
}

sub _interface {
    my ($spec, $type) = @_;

    $type ||= 'interface';
    my %must_allow = (
        interface   => [qw( DOES DESTROY )],
        semiprivate => [qw( BUILD )],
    );
    return { map { $_ => 1 } @{ $spec->{$type} }, @{ $must_allow{$type} } };
}

1;
__END__

=encoding utf-8

=head1 NAME

Minion - build and organise minions declaratively.

=head1 SYNOPSIS

    # Create and use a class
    
    use Test::Most tests => 4;
    use Minion;
    
    my %Class = (
        interface => [qw( next )],
    
        implementation => {
            methods => {
                next => sub {
                    my ($self) = @_;
    
                    $self->{__count}++;
                }
            },
            has  => {
                count => { default => 0 },
            }, 
        },
    );
    
    my $counter = Minion->minionize(\%Class)->new;
    
    is $counter->next => 0;
    is $counter->next => 1;
    is $counter->next => 2;
    
    throws_ok { $counter->new } qr/Can't locate object method "new"/;
    
    
    # Like above but give the class a name
  
    use Test::Most tests => 4;
    use Minion;
    
    my %Class = (
        name => 'Counter',
        interface => [qw( next )],
    
        implementation => {
            methods => {
                next => sub {
                    my ($self) = @_;
    
                    $self->{__count}++;
                }
            },
            has  => {
                count => { default => 0 },
            }, 
        },
    );
    
    Minion->minionize(\%Class);
    my $counter = Counter->new;
    
    is $counter->next => 0;
    is $counter->next => 1;
    
    throws_ok { $counter->new } qr/Can't locate object method "new"/;
    throws_ok { Counter->next } qr/Can't locate object method "next" via package "Counter"/;
    
    
    # Or put code in packages
    
    package Example::Synopsis::Counter;
    
    use strict;
    use Minion;
    
    our %__Meta = (
        interface => [qw( next )],
        implementation => 'Example::Synopsis::Acme::Counter',
    );
    Minion->minionize;  
    
    # In a script near by ...
    
    use Test::Most tests => 3;
    use Example::Synopsis::Counter;
    
    my $counter = Example::Synopsis::Counter->new;
    
    is $counter->next => 0;
    is $counter->next => 1;
    is $counter->next => 2;
    
    # And the implementation for this class:
    
    package Example::Synopsis::Acme::Counter;
    
    use strict;
    
    our %__Meta = (
        has  => {
            count => { default => 0 },
        }, 
    );
    
    sub next {
        my ($self) = @_;
    
        $self->{__count}++;
    }
    
    1;    
    
=head1 DESCRIPTION

Minion is a class builder that simplifies programming in the Object Oriented style as it was originally envisioned
i.e. where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see L<The Deep Insights of Alan Kay|http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/> for further context).

This way of building is more likely to result in systems that are loosely coupled, modular, scalable and easy to maintain.

The words "minion" and "object" are used interchangeably in the rest of this documentation.

Classes are built from a specification hash that declares the interface of the class (i.e. what commands minions of the classs respond to),
as well as other packages that provide the implementation of these commands.

=head1 USAGE

=head2 Minion->minionize([HASHREF])

To build a classs, call the C<minionize()> class method, with an optional hashref that specifies the class.
If the hashref is not given, the specification is read from a package variable named C<%__Meta> in the package
from which C<minionize()> was called.

The meaning of the keys in the specification hash are described next.

=head3 interface => ARRAYREF

A reference to an array containing the messages that minions belonging to this class should respond to.
An exception is raised if this is empty or missing.

The messages named in this array must have corresponding subroutine definitions in a declared implementation
or role package, otherwise an exception is raised.

=head3 implementation => STRING | HASHREF

The name of a package that defines the subroutines declared in the interface.

The package may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the C<$minion-E<gt>command(...)> syntax.

An implementation package (or hash) need not be specified if Roles are used to provide an implementation.

=head3 roles => ARRAYREF

A reference to an array containing the names of one or more Role packages that define the subroutines declared in the interface.

The packages may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the C<$minion-E<gt>command(...)> syntax.

=head3 requires => HASHREF

An optional reference to a hash whose keys are the names of keyword parameters that must be passed to the default constructor.

The values these keys are mapped to are themselves hash refs which can have the following keys.

=head4 assert => HASHREF

A hash that maps a description to a unary predicate (i.e. a sub ref that takes one value and returns true or false).
The default constructor will call these predicates to validate the parameters passed to it.

=head4 attribute => SCALAR

If this is present and has the numerical value 1, this key will become an attribute in the implementation,
having the same name as the key. Use any other true value to give the attribute a different
name.

=head4 reader => SCALAR

This can be a string which if present, and if this key was declared to be an attribute
will be the name of a generated reader method. This can also be the numerical value 1
in which case the generated reader method will have the same name as the key.

=head2 Configuring an implementation package

An implementation package can also be configured with a C<%__Meta> hash with the following keys:

=head3 has => HASHREF

This declares attributes of the implementation, mapping the name of an attribute to a hash with the following keys:

=head4 default => SCALAR | CODEREF

The default value assigned to the attribute when the object is created. This can be an anonymous sub,
which will be excecuted to build the the default value (this would be needed if the default value is a reference,
to prevent all objects from sharing the same reference).

=head4 assert => HASHREF

This is like the C<assert> declared in a class package, except that these assertions are not run at
construction time. Rather they are invoked by calling the semiprivate ASSERT routine.

=head1 AUTHOR

Arun Prasaad E<lt>arunbear@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Arun Prasaad

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v3.

=head1 SEE ALSO

=cut
