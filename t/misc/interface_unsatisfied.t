use strict;
use Test::Lib;
use Test::Most;

{
    package Person;
    use Moduloop ();

    our $Error;
    
    eval { 
        Moduloop->assemble({
            interface => [qw( greet name )],
            implementation => 'PersonImpl',
        });
    }
      or $Error = $@;
}

{
    package PersonImpl;

    use Moduloop::Imp
        has => { name => { reader => 'nmae' } }
    ;

    sub greet {
        my ($self) = @_;
        return "Hello $self->{$NAME}";
    }
}


package main;

like($Person::Error, qr"Interface method 'name' is not implemented.");

done_testing();
