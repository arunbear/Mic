use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package Greeter;

    our %__meta__ = (
        role => 1,
        interface => [qw( greet gday )],
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{-name}";
    }

    sub gday {
        my ($self) = @_;
        return "G'day $self->{-name}";
    }
}

{
    package PersonImpl;

    our %__meta__ = (
        roles => [qw( Greeter )],
    );
}

{
    package Person;

    our %__meta__ = (
        interface => [qw( greet name )],
        implementation => 'PersonImpl',
    );
    our $Error;
    
    eval { Moduloop->minionize }
      or $Error = $@;
}

package main;

isa_ok($Person::Error, 'Moduloop::Error::InterfaceMismatch');

done_testing();
