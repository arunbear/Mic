use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package PersonImpl;

    our %__meta__ = (
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{-name}";
    }
}

{
    package Person;

    our %__meta__ = (
        interface => [qw( greet name )],
        implementation => 'PersonImpl',
    );
    our $Error;
    
    eval { Moduloop->minionize}
      or $Error = $@;
}

package main;

like($Person::Error, qr"Interface method 'name' is not implemented.");

done_testing();
