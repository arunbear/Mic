# NAME

Minion - build and organise minions declaratively.

# SYNOPSIS

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
      

# DESCRIPTION

Minion is a class builder that simplifies programming in the Object Oriented style _as it was originally envisioned_
i.e. where in the words of Alan Kay (who coined the term "Object Oriented Programming") objects are "like biological cells and/or individual computers on a network, only able to communicate with messages"
and "OOP to me means only messaging, local retention and protection and hiding of state-process, and extreme late-binding of all things."
(see [The Deep Insights of Alan Kay](http://mythz.servicestack.net/blog/2013/02/27/the-deep-insights-of-alan-kay/) for further context).

Classes are built from a specification that declares the interface of the class (i.e. what commands minions of the classs respond to),
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

### implementation => STRING | HASHREF

The name of a package that defines the subroutines declared in the interface.

The package may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the `$minion->command(...)` syntax.

An implementation package (or hash) need not be specified if Roles are used to provide an implementation.

### roles => ARRAYREF

A reference to an array containing the names of one or more Role packages that define the subroutines declared in the interface.

The packages may also contain other subroutines not declared in the interface that are for internal use in the package.
These won't be callable using the `$minion->command(...)` syntax.

### requires => HASHREF

A reference to a hash whose keys are the names of keyword parameters that must be passed to the default constructor.

The values these keys are mapped to are themselves hash refs which can have the following keys.

#### assert => HASHREF

A hash that maps a description to a unary predicate (i.e. a sub ref that takes one value and returns true or false).
The default constructor will call these predicates to validate the parameters passed to it.

#### attribute => BOOLEAN

If true, this key will become an attribute in the implementation.

#### reader => SCALAR

This can be a string which if present, and if this key was declared to be an attribute
will be the name of a generated reader method. This can also be the numerical value 1
in which case the generated reader method will have the same name as the key.

# AUTHOR

Arun Prasaad <arunbear@cpan.org>

# COPYRIGHT

Copyright 2014- Arun Prasaad

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v3.

# SEE ALSO
