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
    ;
}

{
    package BusyDude;

    use Moduloop ();
    eval { 
        Moduloop->assemble({
            interface => [qw( serve )],
            implementation => 'BusyDudeImpl'
        });
    }
      or our $Error = $@;
}

package main;

like($BusyDude::Error, qr/Cannot borrow trait 'CLIENTS' from both .*Lawyer/);
like($BusyDude::Error, qr/Cannot borrow trait 'CLIENTS' from both .*Server/);

done_testing();
