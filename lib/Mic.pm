package Mic;

use strict;
use 5.008_005;
use Carp;
use Params::Validate qw(:all);
use Mic::Assembler;

our $VERSION = '0.000003';
$VERSION = eval $VERSION;

my $Class_count = 0;
our %Bound_implementation_of;
our %Contracts_for;
our %Spec_for;
our %Util_class;

sub load_class {
    my ($class, $spec) = @_;

    $spec->{name} ||= "Mic::Class_${\ ++$Class_count }";
    $class->assemble($spec);
}

sub assemble {
    my (undef, $spec) = @_;

    my $assembler = Mic::Assembler->new(-spec => $spec);
    my $cls_stash;
    if ( ! $spec->{name} ) {
        my $depth = 0;
        my $caller_pkg = '';
        my $pkg = __PACKAGE__;

        do {
            $caller_pkg = (caller $depth++)[0];
        }
          while $caller_pkg =~ /^$pkg\b/;
        $spec = $assembler->load_spec_from($caller_pkg);
    }

    my @args = %$spec;
    validate(@args, {
        interface => { type => HASHREF | SCALAR },
        implementation => { type => SCALAR },
        constructor    => { type => HASHREF, optional => 1 },
        name => { type => SCALAR, optional => 1 },
    });
    return $assembler->assemble;
}

*setup_class = \&assemble;

sub builder_for {
    my ($class) = @_;

    return $Util_class{ $class }
      or confess "Unknown class: $class";
}

1;
__END__

=encoding utf-8

=head1 NAME

Mic - Modular OOP made easy.

=head1 SYNOPSIS

    # A simple Set class:

    package Example::Synopsis::Set;

    use Mic
        interface => [ qw( has add ) ], # what the class does

        implementation => 'Example::Synopsis::ArraySet'; # how it does it

    1;


    # And the implementation for this class:

    package Example::Synopsis::ArraySet;

    use Mic::Implementation
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

    use Mic::Implementation
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

    use Mic
        interface => [ qw( has add ) ],

        implementation => 'Example::Synopsis::HashSet'; # updated

    1;

    # Or just

    use Test::More tests => 2;
    use Mic
	bind => { 'Example::Synopsis::Set' => 'Example::Synopsis::HashSet' };
    use Example::Synopsis::Set;

    my $set = Example::Synopsis::Set->new;

    ok ! $set->has(1);
    $set->add(1);
    ok $set->has(1);

=head1 STATUS

This is an early release available for testing and feedback and as such is subject to change.

=head1 DESCRIPTION

Mic is a class building framework with the following features:

=over

=item *

Reduces the tedium and boilerplate code typically involved in creating classes.

=item *

Makes it easy to create classes that are L<modular|http://en.wikipedia.org/wiki/Modular_programming> and loosely coupled.

=item *

Enables trivial swapping of implementations.

=item *

Encourages self documenting code.

=item *

Encourages robustness via Eiffel style L<contracts|Mic::Manual::Contracts>.

=item *

Supports code reuse via automated delegation and importable L<traits|Mic::TraitLib>.

=item *

Supports hash and array based objects.

=back


Modularity means there is a clear and obvious separation between what end users need to know (the interface for using the class) and implementation details that users
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

To see this first hand, try writing the fixed size queue from L<Mic::Implementation/OBJECT COMPOSITION> using L<Moo>, bearing in mind that the only operations the queue should allow are C<push>, C<pop> and C<size>. It is also a revealing exercise to consider how this queue would be written in another language such as Ruby or PHP (e.g. would you need to expose all object attributes via methods?). 

Mic takes inspriation from Moose's declaratve approach to simplifying OO automation, but also aims to put encapsulation and loose coupling on the path of least resistance.

=head1 USAGE

=head2 Via Import

A class can be defined when importing Mic e.g.

    package Foo;

    use Mic
        interface => [ qw( list of methods ) ],

        constructor => { 
            kv_args => {
                # A Params::Validate spec
                arg_name => {
                    # ...
                },
                # ... other args
            }
        },

        implementation => 'An::Implementation::Package',
        ;
    1;

=head2 Mic->assemble([HASHREF])

A class can also be defined by calling the C<assemble()> class method, with an optional hashref that
specifies the class.

If the hashref is not given, the specification is read from a package variable named C<%__meta__> in the package
from which C<assemble()> was called.

The class defined in the SYNOPSIS could also be defined like this

    package Example::Usage::Set;

    use Mic ();

    Mic->assemble({
        interface => [qw( add has )],

        implementation => 'Example::Usage::HashSet',
    });

    package Example::Synopsis::HashSet;

    use Mic::Implementation
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

=head3 interface => ARRAYREF | HASHREF

The interface is a list of messages that objects belonging to this class should respond to.

It can be specified either as a reference to an array (which is how it appears in most examples in this documentation),
or as a reference to a hash, in which case the values of the hash are L<contracts|Mic::Manual::Contracts> on the keys.

An exception is raised if this is empty or missing.

The messages named in this list must have corresponding subroutine definitions in a declared implementation,
otherwise an exception is raised.

=head3 constructor => HASHREF

An optional reference to a hash which can be used to customise the behaviour of the default constructor.

See L<Mic::Manual::Construction> for more about construction.

=head4 name => STRING (Default: 'new')

The name of the constructor.

=head4 kv_args => HASHREF

A hash that usded to define and validate named parameters to the default constructor. See L<Params::Validate> (especially the C<validate> function) for how this validation works.

=head4 ensure => HASHREF

A hash that specifies postconditions that the constructor must satisfy.

Postconditions are described in L<Mic::Manual::Contracts>.

=head3 implementation => STRING

The name of a package that defines the subroutines declared in the interface.

L<Mic::Implementation> describes how implementations are configured.

=head3 invariant => HASHREF

See L<Mic::Manual::Contracts> for more details about invariants.

=head2 Bindings

The implementation of a class can be quite easily changed from user code e.g. after

    use Mic
        bind => { 
            'Foo' => 'Foo::Fake', 
            'Bar' => 'Bar::Fake', 
        };
    use Foo;
    use Bar;

Foo and bar will be bound to fake implementations (e.g. to aid with testing), instead of the implementations defined in
their respective modules.

=head2 Interface Sharing

=head3 declare_interface => ARRAYREF | HASHREF

If two or more classes share a common interface, we can reduce duplication by factoring out that interface using C<declare_interface>, which expects an interface specified in the same way as C<interface> 

Suppose we wanted to use both versions of the set class (from the synopsis) in the same program.

The first step is to extract the common interface:

    package Example::Usage::SetInterface;

    use Mic
        declare_interface => [qw( add has )];
    1;

C<declare_interface> can be used in conjunction with C<invariant>, C<constructor> and C<class_methods>.

=head3 Mic->load_class(HASHREF)

Then implementations of this interface can be loaded via C<load_class>:

    use Test::More tests => 4;
    use Example::Usage::SetInterface;

    my $HashSetClass = Mic->load_class({
        interface      => 'Example::Usage::SetInterface',
        implementation => 'Example::Synopsis::HashSet',
    });

    Mic->load_class({
        interface      => 'Example::Usage::SetInterface',
        implementation => 'Example::Synopsis::ArraySet',
        name           => 'ArraySet',
    });

    my $a_set = 'ArraySet'->new;
    ok ! $a_set->has(1);
    $a_set->add(1);
    ok $a_set->has(1);

    my $h_set = $HashSetClass->new;
    ok ! $h_set->has(1);
    $h_set->add(1);
    ok $h_set->has(1);

C<load_class> expects a hashref with the following keys:

=head4 interface

The name of an interface declared via C<declare_interface>.

=head4 implementation

The name of an implementation package.

=head4 name (optional)

The name of the class via which objects are created.

This is optional and if not given, a synthetic name is used. In either case this name is 
returned by C<load_class>

=head2 Introspection

Behavioural and trait introspection are possible using C<$object-E<gt>can> and C<$object-E<gt>DOES> which if called with no argument will return a list (or array ref depending on context) of methods or traitlibs respectiively supported by the object.

See the section "Using multiple traitlibs" from L<Mic::TraitLib/EXAMPLES> for an example.

Also note that for any class C<Foo> created using Mic, and for any object created with C<Foo>'s constructor, the following will always return a true value

    $object->DOES('Foo')

=head1 BUGS

Please report any bugs or feature requests via the GitHub web interface at
L<https://github.com/arunbear/Mic/issues>.

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
