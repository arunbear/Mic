package Minions;

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
    'Minions::Error::AssertionFailure' => { alias => 'assert_failed' },
    'Minions::Error::InterfaceMismatch',
    'Minions::Error::MethodDeclaration',
    'Minions::Error::RoleConflict',
);
use Minions::_Guts;

our $VERSION = '0.000_004';
$VERSION = eval $VERSION;

my $Class_count = 0;
my %Bound_implementation_of;
my %Interface_for;
my %Util_class;

sub import {
    my ($class, %arg) = @_;

    if ( my $bindings = $arg{bind} ) {

        foreach my $class ( keys %$bindings ) {
            $Bound_implementation_of{$class} = $bindings->{$class};
        }
    }
    elsif ( my $methods = $arg{declare_interface} ) {
        my $caller_pkg = (caller)[0];
        $Interface_for{$caller_pkg} = $methods;
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
        $spec = { %$spec, %{ $cls_stash->get_symbol('%__meta__') || {} } };
        $spec->{name} = $caller_pkg;
    }
    $spec->{name} ||= "Minions::Class_${\ ++$Class_count }";

    my @args = %$spec;
    validate(@args, {
        interface => { type => ARRAYREF | SCALAR },
        implementation => { type => SCALAR | HASHREF },
        construct_with => { type => HASHREF, optional => 1 },
        class_methods  => { type => HASHREF, optional => 1 },
        build_args     => { type => CODEREF, optional => 1 },
        name => { type => SCALAR, optional => 1 },
        no_attribute_vars => { type => BOOLEAN, optional => 1 },
    });
    $cls_stash    ||= Package::Stash->new($spec->{name});
    
    my $obj_stash;

    if ( ! ref $spec->{implementation} ) {
        my $pkg = $Bound_implementation_of{ $spec->{name} } || $spec->{implementation};
        $pkg ne $spec->{name}
          or confess "$spec->{name} cannot be its own implementation.";
        my $stash = _get_stash($pkg);

        my $meta = $stash->get_symbol('%__meta__');
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
    $obj_stash = Package::Stash->new("$spec->{name}::__Minions");
    
    _prep_interface($spec);
    _compose_roles($spec);

    my $private_stash = Package::Stash->new("$spec->{name}::__Private");
    $cls_stash->add_symbol('$__Obj_pkg', $obj_stash->name);
    $cls_stash->add_symbol('$__Private_pkg', $private_stash->name);
    $cls_stash->add_symbol('%__meta__', $spec) if @_ > 0;
    
    _make_util_class($spec);
    _add_class_methods($spec, $cls_stash);
    _add_methods($spec, $obj_stash, $private_stash);
    _check_role_requirements($spec);
    _check_interface($spec);
    return $spec->{name};
}

sub utility_class {
    my ($class) = @_;
    
    return $Util_class{ $class }
      or confess "Unknown class: $class";
}

sub _prep_interface {
    my ($spec) = @_;

    return if ref $spec->{interface};
    my $count = 0;
    {

        if (my $methods = $Interface_for{ $spec->{interface} }) {
            $spec->{interface_name} = $spec->{interface};        
            $spec->{interface} = $methods;        
        }
        else {
            $count > 0 
              and confess "Invalid interface: $spec->{interface}";
            require_module($spec->{interface});
            $count++;
            redo;
        }
    }
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
    my $meta   = $stash->get_symbol('%__meta__');
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

    if ( ! $stash->has_symbol('%__meta__') ) {
        require_module($pkg);
        $stash = Package::Stash->new($pkg);
    }
    if ( ! $stash->has_symbol('%__meta__') ) {
        confess "Package $pkg has no %__meta__";
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
      or Minions::Error::InterfaceMismatch->throw(
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

    Minions::Error::RoleConflict->throw(
        error => "Cannot have '$name' in both $role and $other_role"
    );
}

sub _get_object_maker {

    sub {
        my ($utility_class, $init) = @_;

        my $class = $utility_class->main_class;
        
        my $stash = Package::Stash->new($class);
        my %obj = ( 
            '!' => ${ $stash->get_symbol('$__Private_pkg') },
        );

        my $spec = $stash->get_symbol('%__meta__');
        
        while ( my ($attr, $meta) = each %{ $spec->{implementation}{has} } ) {
            my $obfu_name = Minions::_Guts::obfu_name($attr, $spec);
            $obj{$obfu_name} = $init->{$attr} 
              ? $init->{$attr} 
              : (ref $meta->{default} eq 'CODE'
                ? $meta->{default}->()
                : $meta->{default});
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

    foreach my $sub ( keys %{ $spec->{class_methods} } ) {
        $stash->add_symbol("&$sub", $spec->{class_methods}{$sub});
        subname "$spec->{name}::$sub", $spec->{class_methods}{$sub};
    }
}

sub _make_util_class {
    my ($spec) = @_;
    
    my $stash = Package::Stash->new("$spec->{name}::__Util");
    $Util_class{ $spec->{name} } = $stash->name;

    my %method = (
        new_object => _get_object_maker(),
    );

    $method{main_class} = sub { $spec->{name} };
    
    $method{build} = sub {
        my (undef, $obj, $arg) = @_;
        if ( my $builder = $obj->{'!'}->can('BUILD') ) {
            $builder->($obj->{'!'}, $obj, $arg);
        }
    };
    
    $method{assert} = sub {
        my (undef, $slot, $val) = @_;
        
        return unless exists $spec->{construct_with}{$slot};
        
        my $meta = $spec->{construct_with}{$slot};
        
        for my $desc ( keys %{ $meta->{assert} || {} } ) {
            my $code = $meta->{assert}{$desc};
            $code->($val)
              or assert_failed error => "Parameter '$slot' failed check '$desc'";
        }
    };

    my $class_var_stash = Package::Stash->new("$spec->{name}::__ClassVar");
    
    $method{get_var} = sub {
        my ($class, $name) = @_;
        $class_var_stash->get_symbol($name);
    };

    $method{set_var} = sub {
        my ($class, $name, $val) = @_;
        $class_var_stash->add_symbol($name, $val);
    };

    foreach my $sub ( keys %method ) {
        $stash->add_symbol("&$sub", $method{$sub});
        subname $stash->name."::$sub", $method{$sub};
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

            my $utility_class = utility_class($class);
            my $obj = $utility_class->new_object;
            for my $name ( keys %{ $spec->{construct_with} } ) {

                if ( ! $spec->{construct_with}{$name}{optional} && ! defined $arg->{$name} ) {
                    confess "Param '$name' was not provided.";
                }
                if ( defined $arg->{$name} ) {
                    $utility_class->assert($name, $arg->{$name});
                }

                my ($attr, $dup) = grep { $spec->{implementation}{has}{$_}{init_arg} eq $name } 
                                        keys %{ $spec->{implementation}{has} };
                if ( $dup ) {
                    confess "Cannot have same init_arg '$name' for attributes '$attr' and '$dup'";
                }
                if ( $attr ) {
                    _copy_assertions($spec, $name, $attr);
                    my $sub = $spec->{implementation}{has}{$attr}{map_init_arg};
                    my $obfu_name = Minions::_Guts::obfu_name($attr, $spec) ;
                    $obj->{$obfu_name} = $sub ? $sub->($arg->{$name}) : $arg->{$name};
                }
            }
            
            $utility_class->build($obj, $arg);
            return $obj;
        };
        
        my $build_args = $spec->{build_args} || $spec->{class_methods}{BUILDARGS};
        if ( $build_args ) {
            my $prev_new = $spec->{class_methods}{new};
            
            $spec->{class_methods}{new} = sub {
                my $class = shift;
                $prev_new->($class, $build_args->($class, @_));
            };
        }
    }
}

sub _copy_assertions {
    my ($spec, $name, $attr) = @_;

    my $meta = $spec->{construct_with}{$name};
    
    for my $desc ( keys %{ $meta->{assert} || {} } ) {
        next if exists $spec->{implementation}{has}{$attr}{assert}{$desc};

        $spec->{implementation}{has}{$attr}{assert}{$desc} = $meta->{assert}{$desc};
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
            return (( $spec->{interface_name} ? $spec->{interface_name} : () ), 
                    $spec->{name}, sort keys %{ $spec->{composed_role} });
        }
        
        return    $r eq $spec->{interface_name}
               || $spec->{name} eq $r 
               || $spec->{composed_role}{$r} 
               || $self->isa($r);
    };
    
    while ( my ($name, $meta) = each %{ $spec->{implementation}{has} } ) {

        if ( !  $spec->{implementation}{methods}{$name}
             && $meta->{reader} 
             && $in_interface->{$name} ) {

            my $name = $meta->{reader} == 1 ? $name : $meta->{reader};
            my $obfu_name = Minions::_Guts::obfu_name($name, $spec);
            $spec->{implementation}{methods}{$name} = sub { $_[0]->{$obfu_name} };
        }

        if ( !  $spec->{implementation}{methods}{$name}
             && $meta->{writer}
             && $in_interface->{$name} ) {

            my $name = $meta->{writer} == 1 ? "change_$name" : $meta->{writer};
            $spec->{implementation}{methods}{$name} = sub {
                my ($self, $new_val) = @_;

                $self->{'!'}->ASSERT($name, $new_val);
                $self->{ Minions::_Guts::obfu_name($name, $spec) } = $new_val;
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
        my $obfu_name = Minions::_Guts::obfu_name($name, $spec);
        
        foreach my $meth ( keys %{ $method } ) {
            if ( defined $spec->{implementation}{methods}{$meth} ) {
                confess "Cannot override implemented method '$meth' with a delegated method";
            }
            else {
                my $target = $target_method->{$meth} || $meth;
                $spec->{implementation}{methods}{$meth} =
                  $in_interface->{$meth}
                    ? sub { shift->{$obfu_name}->$target(@_) }
                    : sub { shift; shift->{$obfu_name}->$target(@_) };
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

Minions - What is I<your> API?

=head1 SYNOPSIS

    package Example::Synopsis::Counter;

    use Minions
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
    
    our %__meta__ = (
        has  => {
            count => { default => 0 },
        }, 
    );
    
    sub next {
        my ($self) = @_;
    
        $self->{$A.count}++;
    }
    
    1;    
    
=head1 STATUS

This is an early release available for testing and feedback and as such is subject to change.

=head1 DESCRIPTION

Minions is a class builder that makes it easy to create classes that are L<modular|http://en.wikipedia.org/wiki/Modular_programming>.

Classes are built from a specification that declares the interface of the class (i.e. what commands minions of the classs respond to),
as well as a package that provide the implementation of these commands.

This separation of interface from implementation details is an important aspect of modular design, as it enables modules to be interchangeable (so long as they have the same interface).

It is not a coincidence that the Object Oriented way as it was originally envisioned was mainly concerned with messaging,
where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see L<The Deep Insights of Alan Kay|http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/>).

=head1 RATIONALE

Due to Perl's "assembly required" approach to OOP, there are many CPAN modules that exist to automate this assembly,
perhaps the most popular being the L<Moose> family. Moose is very effective at class building but acheives this at the
expense of Encapsulation (the hiding of implementation details from end users). 
E.g. idiomatic Moose code exposes all of an object's attributes via methods. If we wrote the counter example above
using this approach, we would expose the count attribute via a method even though end users shouldn't need to know about it. 

Minions takes inspriation from Moose's declaratve approach to simplifying OO automation, but does not require or encourage encapsulation to be sacrificed.

=head2 The Tale of Minions

There once was a farmer who had a flock of sheep. His typical workday looked like:

    $farmer->move_flock($pasture)  
    $farmer->monitor_flock()  
    $farmer->move_flock($home)  

    $farmer->other_important_work()  

In order to devote more time to C<other_important_work()>, the farmer decided to hire a minion, so the work was now split like this:     

    $shepherd_boy->move_flock($pasture)  
    $shepherd_boy->monitor_flock()  
    $shepherd_boy->move_flock($home)  

    $farmer->other_important_work()  

This did give the farmer more time for C<other_important_work()>, but unfornately C<$shepherd_boy> had a tendency to L<cry wolf|http://en.wikipedia.org/wiki/The_Boy_Who_Cried_Wolf> so the farmer had to replace him:

    $sheep_dog->move_flock($pasture)  
    $sheep_dog->monitor_flock()  
    $sheep_dog->move_flock($home)  

    $farmer->other_important_work()  

C<$sheep_dog> was more reliable and demanded less pay than C<$shepherd_boy>, so this was a win for the farmer.

Object Oriented design is essentially the act of minionization, i.e. deciding which minions ($objects) will do what work, and how to communicate with them (using an interface).

=head1 USAGE

=head2 Via Import

A class can be defined when importing Minions e.g.

    package Foo;

    use Minions
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

=head2 Minions->minionize([HASHREF])

A class can also be defined by calling the C<minionize()> class method, with an optional hashref that 
specifies the class.

If the hashref is not given, the specification is read from a package variable named C<%__meta__> in the package
from which C<minionize()> was called.

The class defined in the SYNOPSIS could also be defined like this

    use Test::Most tests => 4;
    use Minions ();

    my %Class = (
        name => 'Counter',
        interface => [qw( next )],
        implementation => {
            methods => {
                next => sub {
                    my ($self) = @_;

                    $self->{$A.count}++;
                }
            },
            has  => {
                count => { default => 0 },
            }, 
        },
    );

    Minions->minionize(\%Class);
    my $counter = Counter->new;

    is $counter->next => 0;
    is $counter->next => 1;

    throws_ok { $counter->new } qr/Can't locate object method "new"/;
    throws_ok { Counter->next } qr/Can't locate object method "next" via package "Counter"/;

=head2 Examples

Further examples of usage can be found in the following documents

=over 4

=item L<Minions::Manual::Construction>

=back

=head2 Specification

The meaning of the keys in the specification hash are described next.

=head3 interface => ARRAYREF

A reference to an array containing the messages that minions belonging to this class should respond to.
An exception is raised if this is empty or missing.

The messages named in this array must have corresponding subroutine definitions in a declared implementation,
otherwise an exception is raised.

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

Alternatively an implementation can be hashref as shown in the synopsis above.

L<Minions::Manual::Implementations> describes how implementations are configured.

=head1 BUGS

Please report any bugs or feature requests via the GitHub web interface at 
L<https://github.com/arunbear/perl5-minion/issues>.

=head1 AUTHOR

Arun Prasaad E<lt>arunbear@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Arun Prasaad

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU public license, version 3.

=head1 SEE ALSO

=cut
