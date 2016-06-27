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
        return "Hello I am $self->{$NAME}";
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
    ;
}

{
    package Person;

    use Moduloop ();
    eval { 
        Moduloop->assemble({
            interface => [qw( greet )],
            implementation => 'PersonImpl',
        });
    }
      or our $Error = $@;
}

package main;

like($Person::Error, qr/Attribute 'NAME', required by traitlib Greeter, is not defined/);

done_testing();
