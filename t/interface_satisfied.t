use strict;
use Test::Lib;
use Test::Most;
use Minion;

{
    package Greeter;

    our %__Meta = (
        role => 1,
        requires => { attributes => ['name'] }
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{__name}";
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
    Minion->minionize;
}

package main;

my $person = Person->new(name => 'Bob');
is($person->name, 'Bob', 'required interface method present');

done_testing();
