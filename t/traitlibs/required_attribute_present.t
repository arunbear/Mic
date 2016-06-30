use strict;
use Test::Lib;
use Test::Most;

{
    package Greeter;

    use Moduloop::TraitLib
        requires => { attributes => ['NAME'] }
    ;

    sub greet {
        my ($self) = @_;
        return "Hello, I am $self->{$NAME}";
    }
}

{
    package PersonImpl;

    use Moduloop::Implementation
        traits => {
            Greeter => {
                methods => [qw( greet )],
            },
        },
        has => { NAME => { init_arg => 'name' } }
    ;
}

{
    package Person;

    use Moduloop
        interface => [qw( greet )],
        constructor => {
            kv_args => {
                name => { },
            }
        },
        implementation => 'PersonImpl',
    ;
}

package main;

my $person = Person->new(name => 'Bob');
is($person->greet, 'Hello, I am Bob', 'required attribute present');

done_testing();
