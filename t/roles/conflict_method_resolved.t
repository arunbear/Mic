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

    sub pitch {
        my ($self) = @_;
        return "I'm so busy";
    }
}

{
    package BusyDude;

    use Moduloop
        interface => { 
            object => {
                pitch => {},
            },
            class => { new => {} }
        },
        implementation => 'BusyDudeImpl'
    ;
}

package main;

my $dude = BusyDude->new;
is($dude->pitch, "I'm so busy", 'No trait conflicts');

done_testing();
