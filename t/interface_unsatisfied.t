use strict;
use Test::Lib;
use Test::Most;
use Minion;

{
    package Greeter;

    our %__Meta = (
        role => 1,
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
        construct_with => {
            name => { required => 1 },
        },
        roles => [qw( Greeter )],
    );
    our $Error;
    
    eval { Minion->minionize}
      or $Error = $@;
}

package main;

like($Person::Error, qr"Interface method 'name' is not implemented.");

done_testing();
