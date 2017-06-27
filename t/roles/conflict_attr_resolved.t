use strict;
use Test::Lib;
use Test::Most;

{
    package Lawyer;

    use Moduloop::Role
        has  => { 
            CLIENTS => { default => sub { [] } } 
        }, 
    ;
}

{
    package Server;

    use Moduloop::Role
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
        roles => [qw/Lawyer Server/],
        has => { CLIENTS => { default => sub { [] } } } 
    ;
}

{
    package BusyDude;
    use Moduloop
        interface => { 
            object => {
                serve => {},
            },
            class => { new => {} }
        },
        implementation => 'BusyDudeImpl'
    ;
}

package main;

ok(1, 'No trait conflicts');

done_testing();
