use strict;
use Test::Lib;
use Test::Most;
use Minion ();

{
    package PersonImpl;

    our %__Meta = (
    );

    sub greet {
        my ($self) = @_;
        return "Hello $self->{$$}{name}";
    }
}

{
    package Person;

    our %__Meta = (
        interface => [qw( greet name )],
        implementation => 'PersonImpl',
    );
    our $Error;
    
    eval { Minion->minionize}
      or $Error = $@;
}

package main;

like($Person::Error, qr"Interface method 'name' is not implemented.");

done_testing();
