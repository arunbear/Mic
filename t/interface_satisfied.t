use strict;
use Test::Lib;
use Test::Most;
use Minion;

{
    package Greeter;

    our %__Meta = (
        role => 1,
        has => { 
            name => { 
                init_arg => 'name',
                reader => 1,
            }
        }
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{$$}{name}";
    }
}

{
    package Person;

    our %__Meta = (
        interface => [qw( greet name )],
        construct_with => {
            name => { },
        },
        roles => [qw( Greeter )],
    );
    Minion->minionize;
}

package main;

my $person = Person->new(name => 'Bob');
is($person->name, 'Bob', 'required interface method present');

done_testing();
