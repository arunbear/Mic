package Moduloop;

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
    'Moduloop::Error::AssertionFailure' => { alias => 'assert_failed' },
    'Moduloop::Error::InterfaceMismatch',
    'Moduloop::Error::MethodDeclaration',
    'Moduloop::Error::RoleConflict',
);
use Moduloop::_Guts;

our $VERSION = '1.000000';
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
        $class->assemble(\%arg);
    }
}

sub assemble {
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
    $spec->{name} ||= "Moduloop::Class_${\ ++$Class_count }";

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
            forwards => $meta->{forwards},
            traits   => $meta->{traits},
        };
        my $is_semiprivate = _interface($meta, 'semiprivate');

        foreach my $sub ( keys %{ $spec->{implementation}{methods} } ) {
            if ( $is_semiprivate->{$sub} ) {
                $spec->{implementation}{semiprivate}{$sub} = delete $spec->{implementation}{methods}{$sub};
            }
        }
    }
    $obj_stash = Package::Stash->new("$spec->{name}::__Moduloop");

    _prep_interface($spec);
    _compose_traitlibs($spec);

    my $private_stash = Package::Stash->new("$spec->{name}::__Private");
    $cls_stash->add_symbol('$__Obj_pkg', $obj_stash->name);
    $cls_stash->add_symbol('$__Private_pkg', $private_stash->name);
    $cls_stash->add_symbol('%__meta__', $spec) if @_ > 0;

    _make_builder_class($spec);
    _add_class_methods($spec, $cls_stash);
    _add_methods($spec, $obj_stash, $private_stash);
    _check_traitlib_requirements($spec);
    _check_interface($spec);
    return $spec->{name};
}

sub builder_class {
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

sub _compose_traitlibs {
    my ($spec, $traitlibs, $from_traitlib) = @_;

    if ( ! $traitlibs ) {
        $traitlibs = $spec->{implementation}{traits};
    }

    $from_traitlib ||= {};
    for my $traitlib ( keys %{ $traitlibs } ) {

        if ( $spec->{composed_traitlib}{$traitlib} ) {
            confess "Cannot compose traitlib '$traitlib' twice";
        }
        else {
            $spec->{composed_traitlib}{$traitlib}++;
        }

        my ($meta, $method) = _load_traitlib($traitlib);
        $spec->{required_by_traitlib}{$traitlib} = $meta->{requires};
        _compose_traitlibs($spec, $meta->{traits} || {}, $from_traitlib);

        _add_traitlib_items($spec, $from_traitlib, $traitlib, $meta->{has}, 'has');
        _add_traitlib_methods($spec, $from_traitlib, $traitlib, $meta, $method);
    }
}

sub _load_traitlib {
    my ($traitlib) = @_;

    my $stash  = _get_stash($traitlib);
    my $meta   = $stash->get_symbol('%__meta__');
    $meta->{traitlib}
      or confess "$traitlib is not a traitlib";

    my $method = $stash->get_all_symbols('CODE');
    return ($meta, $method);
}

sub _check_traitlib_requirements {
    my ($spec, $type) = @_;

    $type ||= 'required_by_traitlib';
    my $required_by = do { my $tmp = $type; $tmp =~ s/_/ /g; $tmp };

    foreach my $traitlib ( keys %{ $spec->{$type} } ) {

        my $required = $spec->{$type}{$traitlib};

        foreach my $name ( @{ $required->{methods} } ) {

            unless (   defined $spec->{implementation}{methods}{$name}
                    || defined $spec->{implementation}{semiprivate}{$name}
                   ) {
                confess "Method '$name', $required_by $traitlib, is not implemented.";
            }
        }
        foreach my $name ( @{ $required->{attributes} } ) {
            defined $spec->{implementation}{has}{$name}
              or confess "Attribute '$name', $required_by $traitlib, is not defined.";
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

sub _add_traitlib_items {
    my ($spec, $from_traitlib, $traitlib, $item, $type) = @_;

    my $wanted = $spec->{implementation}{traits}{$traitlib}{attributes};
    for my $name ( @{$wanted} ) {

        if (my $other_traitlib = $from_traitlib->{$name}) {
            _raise_traitlib_conflict($name, $traitlib, $other_traitlib);
        }
        if (exists $item->{$name}) {
            if ( ! $spec->{implementation}{$type}{$name} ) {
                $spec->{implementation}{$type}{$name} = $item->{$name};
                $from_traitlib->{$name} = $traitlib;
            }
        }
        else {
            confess "Attribute '$name' not available via traitlib $traitlib";
        }
    }
}

sub _add_traitlib_methods {
    my ($spec, $from_traitlib, $traitlib, $traitlib_meta, $code_for) = @_;

    my $in_class_interface = _interface($spec);
    my $in_traitlib_interface  = _interface($traitlib_meta);
    my $is_semiprivate     = _interface($traitlib_meta, 'semiprivate');

    all { defined $in_class_interface->{$_} } keys %$in_traitlib_interface
      or Moduloop::Error::InterfaceMismatch->throw(
        error => "Interfaces do not match: Class => $spec->{name}, Role => $traitlib"
      );

    my $wanted = $spec->{implementation}{traits}{$traitlib}{methods};
    for my $name ( @{$wanted} ) {
        if (    $in_traitlib_interface->{$name}
             || $in_class_interface->{$name}
           ) {
            if (my $other_traitlib = $from_traitlib->{method}{$name}) {
                _raise_traitlib_conflict($name, $traitlib, $other_traitlib);
            }
            if ( ! $spec->{implementation}{methods}{$name} ) {
                $spec->{implementation}{methods}{$name} = $code_for->{$name};
                $from_traitlib->{method}{$name} = $traitlib;
            }
        }
        elsif ( $is_semiprivate->{$name} ) {
            if (my $other_traitlib = $from_traitlib->{semiprivate}{$name}) {
                _raise_traitlib_conflict($name, $traitlib, $other_traitlib);
            }
            if ( ! $spec->{implementation}{semiprivate}{$name} ) {
                $spec->{implementation}{semiprivate}{$name} = $code_for->{$name};
                $from_traitlib->{semiprivate}{$name} = $traitlib;
            }
        }
    }
}

sub _raise_traitlib_conflict {
    my ($name, $traitlib, $other_traitlib) = @_;

    Moduloop::Error::RoleConflict->throw(
        error => "Cannot have '$name' in both $traitlib and $other_traitlib"
    );
}

sub _get_object_maker {

    sub {
        my ($builder_class, $init) = @_;

        my $class = $builder_class->main_class;

        my $stash = Package::Stash->new($class);

        my $spec = $stash->get_symbol('%__meta__');
        my $pkg_key = Moduloop::_Guts::obfu_name('', $spec);
        my %obj = (
            $pkg_key => ${ $stash->get_symbol('$__Private_pkg') },
        );

        while ( my ($attr, $meta) = each %{ $spec->{implementation}{has} } ) {
            my $obfu_name = Moduloop::_Guts::obfu_name($attr, $spec);
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

sub _make_builder_class {
    my ($spec) = @_;

    my $stash = Package::Stash->new("$spec->{name}::__Util");
    $Util_class{ $spec->{name} } = $stash->name;

    my %method = (
        new_object => _get_object_maker(),
    );

    $method{main_class} = sub { $spec->{name} };

    my $obfu_pkg = Moduloop::_Guts::obfu_name('', $spec);
    $method{build} = sub {
        my (undef, $obj, $arg) = @_;
        if ( my $builder = $obj->{$obfu_pkg}->can('BUILD') ) {
            $builder->($obj->{$obfu_pkg}, $obj, $arg);
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
            if (my @unknown = grep { ! exists $spec->{construct_with}{$_} } keys %$arg) {
                confess "Unknown args: [@unknown]";
            }

            my $builder_class = builder_class($class);
            my $obj = $builder_class->new_object;
            for my $name ( keys %{ $spec->{construct_with} } ) {

                if ( ! $spec->{construct_with}{$name}{optional} && ! defined $arg->{$name} ) {
                    confess "Param '$name' was not provided.";
                }
                if ( defined $arg->{$name} ) {
                    $builder_class->assert($name, $arg->{$name});
                }

                my ($attr, $dup) = grep { $spec->{implementation}{has}{$_}{init_arg} eq $name }
                                        keys %{ $spec->{implementation}{has} };
                if ( $dup ) {
                    confess "Cannot have same init_arg '$name' for attributes '$attr' and '$dup'";
                }
                if ( $attr ) {
                    _copy_assertions($spec, $name, $attr);
                    my $sub = $spec->{implementation}{has}{$attr}{map_init_arg};
                    my $obfu_name = Moduloop::_Guts::obfu_name($attr, $spec) ;
                    $obj->{$obfu_name} = $sub ? $sub->($arg->{$name}) : $arg->{$name};
                }
            }

            $builder_class->build($obj, $arg);
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
            my @items = (( $spec->{interface_name} ? $spec->{interface_name} : () ),
                          $spec->{name}, sort keys %{ $spec->{composed_role} });
            return unless defined wantarray;
            return wantarray ? @items : \@items;
        }

        return    $r eq $spec->{interface_name}
               || $spec->{name} eq $r
               || $spec->{composed_role}{$r}
               || $self->isa($r);
    };
    $spec->{implementation}{methods}{can} = sub {
        my ($self, $f) = @_;

        if ( ! $f ) {
            my @items = sort @{ $spec->{interface} };
            return unless defined wantarray;
            return wantarray ? @items : \@items;
        }
        return UNIVERSAL::can($self, $f);
    };
    _add_autoload($spec, $stash);

    while ( my ($name, $meta) = each %{ $spec->{implementation}{has} } ) {

        if ( !  $spec->{implementation}{methods}{$name}
             && $meta->{reader}
             && $in_interface->{$name} ) {

            my $name = $meta->{reader} == 1 ? $name : $meta->{reader};
            my $obfu_name = Moduloop::_Guts::obfu_name($name, $spec);
            $spec->{implementation}{methods}{$name} = sub { $_[0]->{$obfu_name} };
        }

        if ( !  $spec->{implementation}{methods}{$name}
             && $meta->{writer}
             && $in_interface->{$name} ) {

            my $name = $meta->{writer};
            my $obfu_pkg = Moduloop::_Guts::obfu_name('', $spec);
            $spec->{implementation}{methods}{$name} = sub {
                my ($self, $new_val) = @_;

                $self->{$obfu_pkg}->ASSERT($name, $new_val);
                $self->{ Moduloop::_Guts::obfu_name($name, $spec) } = $new_val;
                return $self;
            };
        }
    }
    _add_delegates($spec);

    while ( my ($name, $sub) = each %{ $spec->{implementation}{methods} } ) {
        next unless $in_interface->{$name};
        $stash->add_symbol("&$name", subname $stash->name."::$name" => $sub);
    }
    while ( my ($name, $sub) = each %{ $spec->{implementation}{semiprivate} } ) {
        $private_stash->add_symbol("&$name", subname $private_stash->name."::$name" => $sub);
    }
}

sub _add_autoload {
    my ($spec, $stash) = @_;

    $spec->{implementation}{methods}{AUTOLOAD} = sub {
        my $self = shift;

        my $caller_sub = (caller 1)[3];
        my $caller_pkg = $caller_sub;
        $caller_pkg =~ s/::[^:]+$//;

        my $called = ${ $stash->get_symbol('$AUTOLOAD') };
        $called =~ s/.+:://;

        if(    exists $spec->{implementation}{semiprivate}{$called}
            && $caller_pkg eq ref $self
        ) {
            my $stash = _get_stash($spec->{implementation}{package});
            my $sp_var = ${ $stash->get_symbol('$__') };
            return $self->{$sp_var}->$called($self, @_);
        }
        elsif( $called eq 'DESTROY' ) {
            return;
        }
        else {
            croak sprintf(q{Can't locate object method "%s" via package "%s"},
                          $called, ref $self);
        }
    };
}

sub _add_delegates {
    my ($spec) = @_;

    my %local_method;

    foreach my $desc (@{ $spec->{implementation}{forwards} }) {

        my $as = ref $desc->{as} eq 'ARRAY' ? $desc->{as} : [$desc->{as}];
        if(ref $desc->{to} eq 'ARRAY') {
            foreach my $i (0 .. $#{ $desc->{to} }) {
                push @{ $local_method{ $desc->{send} }{targets} }, {
                    to => $desc->{to}[$i],
                    as => $as->[$i] || $desc->{send},
                };
            }
        }
        else {
            my $send = ref $desc->{send} eq 'ARRAY' ? $desc->{send} : [$desc->{send}];
            foreach my $i (0 .. $#$send) {
                push @{ $local_method{ $send->[$i] }{targets} }, {
                    to => $desc->{to},
                    as => $as->[$i] || $send->[$i],
                };
            }
        }
    }

    return unless %local_method;
    my $in_interface = _interface($spec);
    foreach my $meth ( keys %local_method ) {
        if ( defined $spec->{implementation}{methods}{$meth} ) {
            croak "Cannot override implemented method '$meth' with a delegated method";
        }
        $spec->{implementation}{methods}{$meth} = sub { 
            my $obj;
            if( ! $in_interface->{$meth} ) {
                shift;
            }
            $obj = shift;

            my @results;
            foreach my $desc ( @{ $local_method{$meth}{targets} } ) {
                my $obfu_name = Moduloop::_Guts::obfu_name($desc->{to}, $spec);
                my $target = $desc->{as};
                push @results, $obj->{$obfu_name}->$target(@_);
            }
            if (@results == 1) {
                return $results[0];
            }
            return unless defined wantarray;
            return wantarray ? @results : [@results];
        }
    }
}

sub _interface {
    my ($spec, $type) = @_;

    $type ||= 'interface';
    my %must_allow = (
        interface   => [qw( AUTOLOAD can DOES DESTROY )],
        semiprivate => [qw( BUILD )],
    );
    return { map { $_ => 1 } @{ $spec->{$type} }, @{ $must_allow{$type} } };
}

1;
__END__

=encoding utf-8

=head1 NAME

Moduloop - Simplifies the creation of loosely coupled object oriented code.

=head1 SYNOPSIS

    # A simple Set class:

    package Example::Synopsis::Set;

    use Moduloop
        interface => [ qw( has add ) ], # what the class does

        implementation => 'Example::Synopsis::ArraySet'; # how it does it

    1;


    # And the implementation for this class:

    package Example::Synopsis::ArraySet;

    use Moduloop::Implementation
	has => { set => { default => sub { [] } } },
    ;

    sub has {
	my ($self, $e) = @_;
	scalar grep { $_ == $e } @{ $self->{$SET} };
    }

    sub add {
	my ($self, $e) = @_;

	if ( ! $self->has($e) ) {
	    push @{ $self->{$SET} }, $e;
	}
    }

    1;


    # Now we can use it

    use Test::More tests => 2;
    use Example::Synopsis::Set;

    my $set = Example::Synopsis::Set->new;

    ok ! $set->has(1);
    $set->add(1);
    ok $set->has(1);


    # But this has O(n) lookup and we can do better, so:

    package Example::Synopsis::HashSet;

    use Moduloop::Implementation
	has => { set => { default => sub { {} } } },
    ;

    sub has {
	my ($self, $e) = @_;
	exists $self->{$SET}{$e};
    }

    sub add {
	my ($self, $e) = @_;
	++$self->{$SET}{$e};
    }

    1;


    # Now to make use of this we can either:

    package Example::Synopsis::Set;

    use Moduloop
        interface => [ qw( has add ) ],

        implementation => 'Example::Synopsis::HashSet'; # updated

    1;

    # Or just

    use Test::More tests => 2;
    use Moduloop
	bind => { 'Example::Synopsis::Set' => 'Example::Synopsis::HashSet' };
    use Example::Synopsis::Set;

    my $set = Example::Synopsis::Set->new;

    ok ! $set->has(1);
    $set->add(1);
    ok $set->has(1);

=head1 STATUS

This is an early release available for testing and feedback and as such is subject to change.

=head1 DESCRIPTION

Moduloop (Modular OOP [rocks!]) is a class builder that makes it easy to create classes that are L<modular|http://en.wikipedia.org/wiki/Modular_programming>, which means
there is a clear and obvious separation between what end users need to know (the interface for using the class) and implementation details that users
don't need to know about.

Classes are built from a specification that declares the interface of the class (i.e. what commands instances of the classs respond to),
as well as a package that provide the implementation of these commands.

This separation of interface from implementation details is an important aspect of modular design, as it enables modules to be interchangeable (so long as they have the same interface).

It is not a coincidence that the Object Oriented concept as originally envisioned was mainly concerned with messaging,
where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see L<The Deep Insights of Alan Kay|http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/>).

=head1 RATIONALE

Due to Perl's "assembly required" approach to OOP, there are many CPAN modules that exist to automate this assembly,
perhaps the most popular being the L<Moose> family. Although Moo(se) is very effective at simplifying class building, this is typically achieved at the
expense of L<Encapsulation|https://en.wikipedia.org/wiki/Information_hiding> (because Moose encourages the exposure of all an object's attributes via methods), and this in turn encourages
designs that are tightly L<coupled|https://en.wikipedia.org/wiki/Coupling_(computer_programming)>.

To see this first hand, try writing the fixed size queue from L<Moduloop::Implementation/OBJECT COMPOSITION> using L<Moo>, bearing in mind that the only operations the queue should allow are C<push>, C<pop> and C<size>. It is also a revealing exercise to consider how this queue would be written in another language such as Ruby or PHP (e.g. would you need to expose all object attributes via methods?). 

Moduloop takes inspriation from Moose's declaratve approach to simplifying OO automation, but also aims to put encapsulation and loose coupling on the path of least resistance.

=head1 USAGE

=head2 Via Import

A class can be defined when importing Moduloop e.g.

    package Foo;

    use Moduloop
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

=head2 Moduloop->assemble([HASHREF])

A class can also be defined by calling the C<assemble()> class method, with an optional hashref that
specifies the class.

If the hashref is not given, the specification is read from a package variable named C<%__meta__> in the package
from which C<assemble()> was called.

The class defined in the SYNOPSIS could also be defined like this

    package Example::Usage::Set;

    use Moduloop ();

    Moduloop->assemble({
        interface => [qw( add has )],

        implementation => 'Example::Usage::HashSet',
    });

    package Example::Synopsis::HashSet;

    use Moduloop::Implementation
        has => { set => { default => sub { {} } } },
    ;

    sub has {
        my ($self, $e) = @_;
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;
        ++$self->{$SET}{$e};
    }

    1;

Here the interface and implementation packages are both in the same file. 

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

See L<Moduloop::Manual::Construction> for more about construction.

=head4 optional => BOOLEAN (Default: false)

If this is set to a true value, then the corresponding key/value pair need not be passed to the constructor.

=head4 assert => HASHREF

A hash that maps a description to a unary predicate (i.e. a sub ref that takes one value and returns true or false).
The default constructor will call these predicates to validate the parameters passed to it.

=head3 implementation => STRING | HASHREF

The name of a package that defines the subroutines declared in the interface.

Alternatively an implementation can be hashref as shown in the synopsis above.

L<Moduloop::Implementation> describes how implementations are configured.

=head2 Bindings

The implementation of a class can be quite easily changed from user code e.g. after

    use Moduloop
        bind => { 
            'Foo' => 'Foo::Fake', 
            'Bar' => 'Bar::Fake', 
        };
    use Foo;
    use Bar;

Foo and bar will be bound to fake implementations (e.g. to aid with testing), instead of the implementations defined in
their respective modules.

=head2 Introspection

Behavioural and Role introspection are possible using C<$object-E<gt>can> and C<$object-E<gt>DOES> which if called with no argument will return a list (or array ref depending on context) of methods or roles respectiively supported by the object.

See the section "Using multiple roles" from L<Moduloop::Role/EXAMPLES> for an example.

Also note that for any class C<Foo> created using Moduloop, and for any object created with C<Foo>'s constructor, the following will always return a true value

    $object->DOES('Foo')

=head1 BUGS

Please report any bugs or feature requests via the GitHub web interface at
L<https://github.com/arunbear/minions/issues>.

=head1 ACKNOWLEDGEMENTS

Stevan Little (for creating Moose), Tye McQueen (for numerous insights on class building and modular programming).

=head1 AUTHOR

Arun Prasaad E<lt>arunbear@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Arun Prasaad

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU public license, version 3.

=head1 SEE ALSO

=cut
