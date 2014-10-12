use strict;
use Test::Lib;
use Test::Most;
use Minion ();

{
    package Camper;

    our %__Meta = (
        role => 1,
    );

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BaseballPro;

    our %__Meta = (
        role => 1,
    );

    sub pitch {
        my ($self) = @_;
    }
}

{
    package BusyDudeImpl;

    our %__Meta = (
    );

    sub pitch {
        my ($self) = @_;
        return "I'm so busy";
    }
}

{
    package BusyDude;

    our %__Meta = (
        interface => [qw( pitch )],
        roles => [qw( Camper BaseballPro )],
        implementation => 'BusyDudeImpl'
    );
    Minion->minionize;
}

package main;

my $dude = BusyDude->new;
is($dude->pitch, "I'm so busy", '');

done_testing();
