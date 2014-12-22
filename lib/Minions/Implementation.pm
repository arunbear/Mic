package Minions::Implementation;

use strict;
use Package::Stash;

sub import {
    my ($class, %arg) = @_;

    strict->import();

    $arg{-caller} = (caller)[0];
    $class->define(%arg);
}

sub define {
    my ($class, %arg) = @_;
    
    my $caller_pkg = delete $arg{-caller} || (caller)[0];
    my $stash = Package::Stash->new($caller_pkg);
    $class->update_args(\%arg);
    $stash->add_symbol('%__Meta', \%arg);
}

sub update_args {}

1;
