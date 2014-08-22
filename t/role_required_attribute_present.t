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
        return "Hello, I am $self->{__name}";
    }
}

{
    package Person;

    our %__Meta = (
        interface => [qw( greet )],
        roles => [qw( Greeter )],
        has => {
            name => {},
        }
    );
    Minion->minionize;
}

package main;

my $person = Person->new(name => 'Bob');
is($person->greet, 'Hello, I am Bob', 'required attribute present');

done_testing();
