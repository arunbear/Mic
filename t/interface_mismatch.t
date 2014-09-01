use strict;
use Test::Lib;
use Test::Most;
use Minion;

{
    package Greeter;

    our %__Meta = (
        role => 1,
        interface => [qw( greet gday )],
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{__name}";
    }

    sub gday {
        my ($self) = @_;
        return "G'day $self->{__name}";
    }
}

{
    package Person;

    our %__Meta = (
        interface => [qw( greet name )],
        roles => [qw( Greeter )],
        requires => {
            name => { reader => 1 },
        }
    );
    our $Error;
    
    eval { Minion->minionize }
      or $Error = $@;
}

package main;

isa_ok($Person::Error, 'Minion::Error::InterfaceMismatch');

done_testing();
