use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package Lawyer;

    our %__meta__ = (
        role => 1,
        has  => { clients => { default => sub { [] } } } 
    );
}

{
    package Server;

    our %__meta__ = (
        role => 1,
        has  => { clients => { default => sub { [] } } } 
    );

    sub serve {
        my ($self) = @_;
    }
}

{
    package BusyDudeImpl;

    our %__meta__ = (
        roles => [qw( Lawyer Server )],
        has  => { clients => { default => sub { [] } } } 
    );
}

{
    package BusyDude;

    our %__meta__ = (
        interface => [qw( serve )],
        implementation => 'BusyDudeImpl'
    );
    Moduloop->minionize;
}

package main;

ok(1, 'No role conflicts');

done_testing();
