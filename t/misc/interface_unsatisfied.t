use strict;
use Test::Lib;
use Test::Most;

{
    package Person;
    use Moduloop ();

    our $Error;
    
    eval { 
        Moduloop->assemble({
            interface => { 
                object => {
                    greet => {},
                    name => {},
                },
                class => { new => {} }
            },
            implementation => 'PersonImpl',
        });
    }
      or $Error = $@;
}

{
    package PersonImpl;

    use Moduloop::Impl
        has => { NAME => { reader => 'nmae' } }
    ;

    sub greet {
        my ($self) = @_;
        return "Hello $self->[ $NAME ]";
    }
}


package main;

like($Person::Error, qr"Interface method 'name' is not implemented.");

done_testing();
