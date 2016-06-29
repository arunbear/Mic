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
                methods => [qw( charlie )],
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

    sub charliex { 'charlie' }
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
            interface => [qw( alpha bravo charlie delta )],
            implementation => 'AlphabetImpl',
        });
    }
      or our $Error = $@;
}

package main;

like($Alphabet::Error, qr/Interface method 'charlie' is not implemented/);

done_testing();
