use strict;
use Test::Lib;
use Test::Most;

{
    package Lawyer;

    use Moduloop::TraitLib
        has  => { 
            CLIENTS => { default => sub { [] } } 
        }, 
    ;
}

{
    package Server;

    use Moduloop::TraitLib
        has  => { 
            CLIENTS => { default => sub { [] } } 
        }, 
    ;

    sub serve {
        my ($self) = @_;
    }
}

{
    package BusyDudeImpl;

    use Moduloop::Implementation
        traits => {
            Lawyer => {
                attributes => ['CLIENTS']
            },
            Server => {
                methods    => [qw( serve )],
                attributes => ['CLIENTS']
            }
        },
        has => { CLIENTS => { default => sub { [] } } } 
    ;
}

{
    package BusyDude;
    use Moduloop
        interface => [qw( serve )],
        implementation => 'BusyDudeImpl'
    ;
}

package main;

ok(1, 'No trait conflicts');

done_testing();
