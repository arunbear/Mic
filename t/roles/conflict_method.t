use strict;
use Test::Lib;
use Test::Most;

{
    package Camper;

    use Moduloop::Role;

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BaseballPro;

    use Moduloop::Role;

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BusyDudeImpl;

    use Moduloop::Implementation
        roles => [qw/Camper BaseballPro/],
    ;
}

{
    package BusyDude;

    use Moduloop ();
    eval { 
        Moduloop->assemble({
            interface => { 
                object => {
                    pitch => {},
                },
                class => { new => {} }
            },
            implementation => 'BusyDudeImpl'
        });
    }
      or our $Error = $@;
}

package main;

like($BusyDude::Error, qr/Cannot have 'pitch' in both BaseballPro and Camper/);

done_testing();
