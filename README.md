# NAME

Minion - Spartans! What is _your_ API?

# SYNOPSIS

    use Minion;
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
    
    # Now some 'normal' examples
    
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
    
        $self->{$$}{count}++;
    }
    
    1;    
    

# DESCRIPTION

Minion is a class builder that simplifies the creation of loosely coupled Object Oriented systems.

The Object Oriented way as it was originally envisioned was more concerned with messaging,
where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see [The Deep Insights of Alan Kay](http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/) for further inspiration).

This way of building is more likely to result in systems that are loosely coupled, modular, scalable and easy to maintain.

The words "minion" and "object" are used interchangeably in the rest of this documentation.

Classes are built from a specification hash that declares the interface of the class (i.e. what commands minions of the classs respond to),
as well as other packages that provide the implementation of these commands.

# USAGE

## Minion->minionize(\[HASHREF\])

To build a classs, call the `minionize()` class method, with an optional hashref that specifies the class.
If the hashref is not given, the specification is read from a package variable named `%__Meta` in the package
from which `minionize()` was called.

The meaning of the keys in the specification hash are described next.

### interface => ARRAYREF

A reference to an array containing the messages that minions belonging to this class should respond to.
An exception is raised if this is empty or missing.

The messages named in this array must have corresponding subroutine definitions in a declared implementation
or role package, otherwise an exception is raised.

### construct\_with => HASHREF

An optional reference to a hash whose keys are the names of keyword parameters that are passed to the default constructor.

The values these keys are mapped to are themselves hash refs which can have the following keys.

#### optional => BOOLEAN

If this is set to a true value, then the corresponding key/value pair need not be passed to the constructor.

#### assert => HASHREF

A hash that maps a description to a unary predicate (i.e. a sub ref that takes one value and returns true or false).
The default constructor will call these predicates to validate the parameters passed to it.

### implementation => STRING | HASHREF

The name of a package that defines the subroutines declared in the interface.

The package may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the `$minion->command(...)` syntax.

An implementation package (or hash) need not be specified if Roles are used to provide an implementation.

### roles => ARRAYREF

A reference to an array containing the names of one or more Role packages that define the subroutines declared in the interface.

The packages may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the `$minion->command(...)` syntax.

## Configuring an implementation package

An implementation package can also be configured with a package variable `%__Meta` with the following keys:

### has => HASHREF

This declares attributes of the implementation, mapping the name of an attribute to a hash with keys described in
the following sub sections.

An attribute called "foo" can be accessed via it's object like this:

    $self->{$$}{foo}

i.e. the attribute name preceeded by two underscores. Objects created by Minion are hashes,
and are locked down to allow only keys declared in the "has" (implementation or role level)
declarations. This is done to prevent accidents like 
mis-spelling an attribute name.

#### default => SCALAR | CODEREF

The default value assigned to the attribute when the object is created. This can be an anonymous sub,
which will be excecuted to build the the default value (this would be needed if the default value is a reference,
to prevent all objects from sharing the same reference).

#### assert => HASHREF

This is like the `assert` declared in a class package, except that these assertions are not run at
construction time. Rather they are invoked by calling the semiprivate ASSERT routine.

#### handles => ARRAYREF | HASHREF | SCALAR

This declares that methods can be forwarded from the object to this attribute in one of three ways
described below. These forwarding methods are generated as public methods if they are declared in
the interface, and as semiprivate routines otherwise.

#### handles => ARRAYREF

All methods in the given array will be forwarded.

#### handles => HASHREF

Method forwarding will be set up such that a method whose name is a key in the given hash will be
forwarded to a method whose name is the corresponding value in the hash.

#### handles => SCALAR

The scalar is assumed to be a role, and methods provided directly (i.e. not including methods in sub-roles) by the role will be forwarded.

#### reader => SCALAR

This can be a string which if present will be the name of a generated reader method.

This can also be the numerical value 1 in which case the generated reader method will have the same name as the key.

Readers should only be created if they are logically part of the class API.

### semiprivate => ARRAYREF

Any subroutines in this list will be semiprivate, i.e. they will not be callable as regular object methods but
can be called using the syntax:

    $obj->{'!'}->do_something(...)

## Configuring a role package

A role package must be configured with a package variable `%__Meta` with the following keys (of which only "role"
is mandatory):

### role => 1 (Mandatory)

This indicates that the package is a Role.

### has => HASHREF

This works the same way as in an implementation package.

### semiprivate => ARRAYREF

This works the same way as in an implementation package.

### requires => HASHREF

A hash with keys:

#### methods => ARRAYREF

Any methods listed here must be provided by an implementation package or a role.

#### attributes => ARRAYREF

Any attributes listed here must be provided by an implementation package or a role, or by the "requires"
definition in the class.

## Special Class Methods

These special class methods are useful in cases where the default constructor is not flexible enough
and you need to write your own constructor.

### \_\_new\_\_

This creates a new instance, in which attributes with declared defaults are populated with those defaults,
and all others are populated with undef.

### \_\_build\_\_

This can be used in a class method to invoke the semiprivate BUILD routine for an object after the object
is created.

### \_\_assert\_\_

Given the name of a declared attribute and a value, this routine validates the value using any assertions
declared with the attribute.

## Constructor Hooks

These are optional routines that can be used to customise the default construction process. 

### BUILDARGS

If this class method is defined, it will receive all parameters intended for `new()`, and its
result (which should be a hash list or hashref) will be passed to `new()`.

This is useful when the constructor requires positional rather than keyword parameters.

### BUILD

If this semiprivate method is defined, it will be called by the default constructor and
will receive the object and a hashref of named parameters that were passed to the constructor.

This is useful for carrying out any post-construction logic e.g. object validation.

# BUGS

Please report any bugs or feature requests via the GitHub web interface at 
[https://github.com/arunbear/perl5-minion/issues](https://github.com/arunbear/perl5-minion/issues).

# AUTHOR

Arun Prasaad <arunbear@cpan.org>

# COPYRIGHT

Copyright 2014- Arun Prasaad

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v3.

# SEE ALSO
