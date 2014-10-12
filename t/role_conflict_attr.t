use strict;
use Test::Lib;
use Test::Most;
use Minion ();

{
    package Lawyer;

    our %__Meta = (
        role => 1,
        has  => { clients => { default => sub { [] } } } 
    );
}

{
    package Server;

    our %__Meta = (
        role => 1,
        has  => { clients => { default => sub { [] } } } 
    );

    sub serve {
        my ($self) = @_;
    }
}

{
    package BusyDude;

    our %__Meta = (
        interface => [qw( serve )],
        roles => [qw( Lawyer Server )],
    );
}
package main;

throws_ok {
    Minion->minionize(\ %BusyDude::__Meta);
} qr/Cannot have 'clients' in both Server and Lawyer/;

done_testing();
