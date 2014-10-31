use strict;
use Test::Lib;
use Test::Most;
use Minion ();

{
    package Greeter;

    our %__Meta = (
        role => 1,
        interface => [qw( greet gday )],
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{$$}{name}";
    }

    sub gday {
        my ($self) = @_;
        return "G'day $self->{$$}{name}";
    }
}

{
    package PersonImpl;

    our %__Meta = (
        roles => [qw( Greeter )],
    );
}

{
    package Person;

    our %__Meta = (
        interface => [qw( greet name )],
        implementation => 'PersonImpl',
    );
    our $Error;
    
    eval { Minion->minionize }
      or $Error = $@;
}

package main;

isa_ok($Person::Error, 'Minion::Error::InterfaceMismatch');

done_testing();
