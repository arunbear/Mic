use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package Alpha;

    use Moduloop::TraitLib
        traits => {
            Bravo => {
                methods => [qw( bravo delta )],
            },
            Charlie => {
                methods => [qw( charliex )],
            },
        },
    ;

    sub alpha { 'alpha' }
}

{
    package Bravo;

    use Moduloop::TraitLib
        traits => {
            Delta => {
                methods => [qw( delta )],
            },
        },
    ;

    sub bravo { 'bravo' }
}

{
    package Charlie;

    use Moduloop::TraitLib;

    sub charlie { 'charlie' }
}

{
    package Delta;

    use Moduloop::TraitLib;

    sub delta { 'delta' }
}

{
    package AlphabetImpl;

    use Moduloop::Implementation
        traits => {
            Alpha => {
                methods => [qw( alpha bravo charlie delta )],
            },
        },
    ;
}

{
    package Alphabet;

    use Moduloop ();
    eval { 
        Moduloop->assemble({
            interface => { 
                object => {
                    alpha   => {},
                    bravo   => {},
                    charlie => {},
                    delta   => {},
                },
                class => { new => {} }
            },
            implementation => 'AlphabetImpl',
        });
    }
      or our $Error = $@;
}

package main;

like($Alphabet::Error, qr/Interface method 'charlie' is not implemented/);

done_testing();
