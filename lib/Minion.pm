package Minion;

use strict;
use 5.008_005;
use Carp;
use Hash::Util qw( lock_keys );
use List::MoreUtils qw( all );
use Module::Runtime qw( require_module );
use Params::Validate qw(:all);
use Package::Stash;
use Sub::Name;

use Exception::Class (
    'Minion::Error::AssertionFailure' => { alias => 'assert_failed' },
    'Minion::Error::InterfaceMismatch',
    'Minion::Error::MethodDeclaration',
    'Minion::Error::RoleConflict',
);

our $VERSION = 0.000_001;

my $Class_count = 0;
my %Bound_implementation_of;

sub import {
    my ($class, %arg) = @_;

    if ( my $bindings = $arg{bind} ) {

        foreach my $class ( keys %$bindings ) {
            $Bound_implementation_of{$class} = $bindings->{$class};
        }
    }
    else {
        $class->minionize(\%arg);
    }
}

sub minionize {
    my (undef, $spec) = @_;

    my $cls_stash;
    if ( ! $spec->{name} ) {
        my $caller_pkg = (caller)[0];

        if ( $caller_pkg eq __PACKAGE__ ) {
            $caller_pkg = (caller 1)[0];
        }
        $cls_stash = Package::Stash->new($caller_pkg);
        $spec = { %$spec, %{ $cls_stash->get_symbol('%__Meta') || {} } };
        $spec->{name} = $caller_pkg;
    }
    $spec->{name} ||= "Minion::Class_${\ ++$Class_count }";

    my @args = %$spec;
    validate(@args, {
        interface => { type => ARRAYREF },
        implementation => { type => SCALAR | HASHREF },
        construct_with => { type => HASHREF, optional => 1 },
        class_methods  => { type => HASHREF, optional => 1 },
        name => { type => SCALAR, optional => 1 },
    });
    $cls_stash    ||= Package::Stash->new($spec->{name});
    
    my $obj_stash;

    if ( ! ref $spec->{implementation} ) {
        my $pkg = $Bound_implementation_of{ $spec->{name} } || $spec->{implementation};
        $pkg ne $spec->{name}
          or confess "$spec->{name} cannot be its own implementation.";
        my $stash = _get_stash($pkg);

        my $meta = $stash->get_symbol('%__Meta');
        $spec->{implementation} = { 
            package => $pkg, 
            methods => $stash->get_all_symbols('CODE'),
            has     => {
                %{ $meta->{has} || { } },
            },
        };
        $spec->{roles} = $meta->{roles};
        my $is_semiprivate = _interface($meta, 'semiprivate');

        foreach my $sub ( keys %{ $spec->{implementation}{methods} } ) {
            if ( $is_semiprivate->{$sub} ) {
                $spec->{implementation}{semiprivate}{$sub} = delete $spec->{implementation}{methods}{$sub};
            }
        }
    }
    $obj_stash = Package::Stash->new("$spec->{name}::__Minion");
    
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
        my %obj = ( 
            '!' => ${ $stash->get_symbol('$__Private_pkg') },
            $$  => {}, 
        );

        my $spec = $stash->get_symbol('%__Meta');
        
        while ( my ($attr, $meta) = each %{ $spec->{implementation}{has} } ) {
            $obj{$$}{$attr} = ref $meta->{default} eq 'CODE'
              ? $meta->{default}->()
              : $meta->{default};
        }
        lock_keys(%{ $obj{$$} });
        
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
        
        return unless exists $spec->{construct_with}{$slot};
        
        my $meta = $spec->{construct_with}{$slot};
        
        for my $desc ( keys %{ $meta->{assert} || {} } ) {
            my $code = $meta->{assert}{$desc};
            $code->($val)
              or assert_failed error => "Parameter '$slot' failed check '$desc'";
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
            for my $name ( keys %{ $spec->{construct_with} } ) {

                if ( ! $spec->{construct_with}{$name}{optional} && ! defined $arg->{$name} ) {
                    confess "Param '$name' was not provided.";
                }
                $class->__assert__($name, $arg->{$name});

                my ($attr, $dup) = grep { $spec->{implementation}{has}{$_}{init_arg} eq $name } 
                                        keys %{ $spec->{implementation}{has} };
                if ( $dup ) {
                    confess "Cannot have same init_arg '$name' for attributes '$attr' and '$dup'";
                }
                if ( $attr ) {
                    $obj->{$$}{$attr} = $arg->{$name};
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
              or assert_failed error => "Attribute '$slot' failed check '$desc'";
        }
    };
    $spec->{implementation}{methods}{DOES} = sub {
        my ($self, $r) = @_;
        
        if ( ! $r ) {
            return ($spec->{name}, sort keys %{ $spec->{composed_role} });
        }
        
        $spec->{name} eq $r || $spec->{composed_role}{$r} || $self->isa($r);
    };
    
    while ( my ($name, $meta) = each %{ $spec->{implementation}{has} } ) {

        if ( !  $spec->{implementation}{methods}{$name}
             && $meta->{reader} 
             && $in_interface->{$name} ) {

            my $name = $meta->{reader} == 1 ? $name : $meta->{reader};
            $spec->{implementation}{methods}{$name} = sub { $_[0]->{$$}{$name} };
        }

        if ( !  $spec->{implementation}{methods}{$name}
             && $meta->{writer}
             && $in_interface->{$name} ) {

            my $name = $meta->{writer} == 1 ? "change_$name" : $meta->{writer};
            $spec->{implementation}{methods}{$name} = sub {
                my ($self, $new_val) = @_;

                $self->{'!'}->ASSERT($name, $new_val);
                $self->{$$}{$name} = $new_val;
                return $self;
            };
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
                    ? sub { shift->{$$}{$name}->$target(@_) }
                    : sub { shift; shift->{$$}{$name}->$target(@_) };
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

Minion - Spartans! What is I<your> API?

=head1 SYNOPSIS

    use Minion ();
    use v5.10;
    
    Minion->minionize({
        name => 'Spartan',
        interface => [qw( fight train party )], # This is what Spartans do
    
        # And this is how they do it:
        implementation => {
            methods => {
                fight => sub { say "Spartan $_[0]->{$$}{id} is fighting" },
                train => sub { say "Spartan $_[0]->{$$}{id} is training" },
                party => sub { say "Spartan $_[0]->{$$}{id} is partying" },
            },
            has  => {
                id => { default => sub { ++$main::_Count } },
            }, 
        },
    });
    my @spartans = map { Spartan->new } 1 .. 300;
    
    foreach my $spartan ( @spartans ) {
        $spartan->fight;
    }
    # ... other horrible events
    
    # Now a more 'normal' example
    
    package Example::Synopsis::Counter;

    use Minion
        interface => [ qw( next ) ],
        implementation => 'Example::Synopsis::Acme::Counter';

    1;
    
    # In a script near by ...
    
    use Test::Most tests => 5;
    use Example::Synopsis::Counter;

    my $counter = Example::Synopsis::Counter->new;

    is $counter->next => 0;
    is $counter->next => 1;
    is $counter->next => 2;

    throws_ok { $counter->new } qr/Can't locate object method "new"/;
    
    throws_ok { Example::Synopsis::Counter->next } 
              qr/Can't locate object method "next" via package "Example::Synopsis::Counter"/;

    
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
    
        $self->{$$}{count}++;
    }
    
    1;    
    
=head1 DESCRIPTION

Minion is a class builder that simplifies the creation of loosely coupled Object Oriented systems.

The Object Oriented way as it was originally envisioned was more concerned with messaging,
where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see L<The Deep Insights of Alan Kay|http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/> for further inspiration).

This way of building is more likely to result in systems that are loosely coupled, modular, scalable and easy to maintain.

The words "minion" and "object" are used interchangeably in the rest of this documentation.

Classes are built from a specification hash that declares the interface of the class (i.e. what commands minions of the classs respond to),
as well as other packages that provide the implementation of these commands.

=head1 USAGE

=head2 Via Import

A class can be defined when importing Minion e.g.

    package Foo;

    use Minion
        interface => [ qw( list of methods ) ],

        construct_with => {
            arg_name => {
                assert => {
                    desc => sub {
                        # return true if arg is valid
                        # or false otherwise
                    }
                },
                optional => $boolean,
            },
            # ... other args
        },

        implementation => 'An::Implementation::Package',
        ;
    1;

=head2 Minion->minionize([HASHREF])

A class can also be defined by calling the C<minionize()> class method, with an optional hashref that 
specifies the class as outlined above.

If the hashref is not given, the specification is read from a package variable named C<%__Meta> in the package
from which C<minionize()> was called.

The meaning of the keys in the specification hash are described next.

=head3 interface => ARRAYREF

A reference to an array containing the messages that minions belonging to this class should respond to.
An exception is raised if this is empty or missing.

The messages named in this array must have corresponding subroutine definitions in a declared implementation
or role package, otherwise an exception is raised.

=head3 construct_with => HASHREF

An optional reference to a hash whose keys are the names of keyword parameters that are passed to the default constructor.

The values these keys are mapped to are themselves hash refs which can have the following keys.

=head4 optional => BOOLEAN (Default: false)

If this is set to a true value, then the corresponding key/value pair need not be passed to the constructor.

=head4 assert => HASHREF

A hash that maps a description to a unary predicate (i.e. a sub ref that takes one value and returns true or false).
The default constructor will call these predicates to validate the parameters passed to it.

=head3 implementation => STRING | HASHREF

The name of a package that defines the subroutines declared in the interface.

The package may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the C<$minion-E<gt>command(...)> syntax.

An implementation package (or hash) need not be specified if Roles are used to provide an implementation.

Alternatively an implementation can be hashref as shown in the synopsis above.

=head3 roles => ARRAYREF

A reference to an array containing the names of one or more Role packages that define the subroutines declared in the interface.

The packages may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the C<$minion-E<gt>command(...)> syntax.

=head2 Configuring an implementation package

An implementation package can also be configured with a package variable C<%__Meta> with the following keys:

=head3 has => HASHREF

This declares attributes of the implementation, mapping the name of an attribute to a hash with keys described in
the following sub sections.

An attribute called "foo" can be accessed via it's object like this:

    $self->{$$}{foo}

i.e. the attribute name preceeded by two underscores. Objects created by Minion are hashes,
and are locked down to allow only keys declared in the "has" (implementation or role level)
declarations. This is done to prevent accidents like 
mis-spelling an attribute name.

=head4 default => SCALAR | CODEREF

The default value assigned to the attribute when the object is created. This can be an anonymous sub,
which will be excecuted to build the the default value (this would be needed if the default value is a reference,
to prevent all objects from sharing the same reference).

=head4 assert => HASHREF

This is like the C<assert> declared in a class package, except that these assertions are not run at
construction time. Rather they are invoked by calling the semiprivate ASSERT routine.

=head4 handles => ARRAYREF | HASHREF | SCALAR

This declares that methods can be forwarded from the object to this attribute in one of three ways
described below. These forwarding methods are generated as public methods if they are declared in
the interface, and as semiprivate routines otherwise.

=head4 handles => ARRAYREF

All methods in the given array will be forwarded.

=head4 handles => HASHREF

Method forwarding will be set up such that a method whose name is a key in the given hash will be
forwarded to a method whose name is the corresponding value in the hash.

=head4 handles => SCALAR

The scalar is assumed to be a role, and methods provided directly (i.e. not including methods in sub-roles) by the role will be forwarded.

=head4 reader => SCALAR

This can be a string which if present will be the name of a generated reader method.

This can also be the numerical value 1 in which case the generated reader method will have the same name as the key.

Readers should only be created if they are logically part of the class API.

=head3 semiprivate => ARRAYREF

Any subroutines in this list will be semiprivate, i.e. they will not be callable as regular object methods but
can be called using the syntax:

    $obj->{'!'}->do_something(...)

=head2 Configuring a role package

A role package must be configured with a package variable C<%__Meta> with the following keys (of which only "role"
is mandatory):
 
=head3 role => 1 (Mandatory)

This indicates that the package is a Role.

=head3 has => HASHREF

This works the same way as in an implementation package.

=head3 semiprivate => ARRAYREF

This works the same way as in an implementation package.

=head3 requires => HASHREF

A hash with keys:

=head4 methods => ARRAYREF

Any methods listed here must be provided by an implementation package or a role.

=head4 attributes => ARRAYREF

Any attributes listed here must be provided by an implementation package or a role, or by the "requires"
definition in the class.

=head2 Special Class Methods

These special class methods are useful in cases where the default constructor is not flexible enough
and you need to write your own constructor.

=head3 __new__

This creates a new instance, in which attributes with declared defaults are populated with those defaults,
and all others are populated with undef.

=head3 __build__

This can be used in a class method to invoke the semiprivate BUILD routine for an object after the object
is created.

=head3 __assert__

Given the name of a declared attribute and a value, this routine validates the value using any assertions
declared with the attribute.

=head2 Constructor Hooks

These are optional routines that can be used to customise the default construction process. 

=head3 BUILDARGS

If this class method is defined, it will receive all parameters intended for C<new()>, and its
result (which should be a hash list or hashref) will be passed to C<new()>.

This is useful when the constructor requires positional rather than keyword parameters.

=head3 BUILD

If this semiprivate method is defined, it will be called by the default constructor and
will receive the object and a hashref of named parameters that were passed to the constructor.

This is useful for carrying out any post-construction logic e.g. object validation.

=head1 BUGS

Please report any bugs or feature requests via the GitHub web interface at 
L<https://github.com/arunbear/perl5-minion/issues>.

=head1 AUTHOR

Arun Prasaad E<lt>arunbear@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Arun Prasaad

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v3.

=head1 SEE ALSO

=cut
