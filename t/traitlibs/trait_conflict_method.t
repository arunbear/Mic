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
}

{
    package BusyDude;

    use Moduloop ();
    eval { 
        Moduloop->assemble({
            interface => [qw( pitch )],
            implementation => 'BusyDudeImpl'
        });
    }
      or our $Error = $@;
}

package main;

like($BusyDude::Error, qr/Cannot borrow trait 'pitch' from both .*BaseballPro/);
like($BusyDude::Error, qr/Cannot borrow trait 'pitch' from both .*Camper/);

done_testing();
