use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package Greeter;

    use Moduloop::Role
        requires => { attributes => ['name'] }
    ;

    sub greet {
        my ($self) = @_;
        return "Hello $self->{$NAME}";
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
        interface => [qw( greet )],
        implementation => 'PersonImpl',
    );
}

package main;

throws_ok {
    Moduloop->minionize(\ %Person::__meta__);
} qr/Attribute 'name', required by role Greeter, is not defined./;

done_testing();
