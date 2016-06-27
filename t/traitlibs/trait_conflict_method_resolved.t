use strict;
use Test::Lib;
use Test::Most;

{
    package Camper;

    use Moduloop::TraitLib;

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BaseballPro;

    use Moduloop::TraitLib;

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BusyDudeImpl;

    use Moduloop::Implementation
        traits => {
            Camper => {
                methods    => [qw( pitch )],
            },
            BaseballPro => {
                methods    => [qw( pitch )],
            }
        },
    ;

    sub pitch {
        my ($self) = @_;
        return "I'm so busy";
    }
}

{
    package BusyDude;

    use Moduloop
        interface => [qw( pitch )],
        implementation => 'BusyDudeImpl'
    ;
}

package main;

my $dude = BusyDude->new;
is($dude->pitch, "I'm so busy", 'No trait conflicts');

done_testing();
