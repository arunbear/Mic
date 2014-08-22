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
        interface => [qw( greet )],
        roles => [qw( Greeter )],
    );
}

package main;

throws_ok {
    Minion->minionize(\ %Person::__Meta);
} qr/Attribute 'name', required by role Greeter, is not defined./;

done_testing();
