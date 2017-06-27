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
    ;
}

{
    package BusyDude;

    use Moduloop ();
    eval { 
        Moduloop->assemble({
            interface => { 
                object => {
                    serve => {},
                },
                class => { new => {} }
            },
            implementation => 'BusyDudeImpl'
        });
    }
      or our $Error = $@;
}

package main;

like($BusyDude::Error, qr/Cannot have 'CLIENTS' in both Server and Lawyer/);

done_testing();
