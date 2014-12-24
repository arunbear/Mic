# use strict;
use Test::Lib;
use Test::Most;
use Minions ();

{
    package Greeter;

    use Minions::Role
        requires => { attributes => ['name'] }
    ;

    sub greet {
        my ($self) = @_;
        return "Hello, I am $self->{$__Name}";
    }
}

{
    package PersonImpl;
    use Minions::Implementation
        roles => [qw( Greeter )],
        has => { name => { init_arg => 'name' } }
    ;
}

{
    package Person;

    our %__Meta = (
        interface => [qw( greet )],
        construct_with => {
            name => { },
        },
        implementation => 'PersonImpl',
    );
    Minions->minionize;
}

package main;

my $person = Person->new(name => 'Bob');
is($person->greet, 'Hello, I am Bob', 'required attribute present');

done_testing();
