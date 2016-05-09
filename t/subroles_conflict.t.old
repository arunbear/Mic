use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package Alpha;

    our %__meta__ = (
        role => 1,
        roles => [qw( Bravo Charlie )]
    );

    sub alpha { 'alpha' }
}

{
    package Bravo;

    our %__meta__ = (
        role => 1,
        roles => [qw( Delta )]
    );

    sub bravo { 'bravo' }
}

{
    package Charlie;

    our %__meta__ = (
        role => 1,
    );

    sub charlie { 'charlie' }
}

{
    package Delta;

    our %__meta__ = (
        role => 1,
    );

    sub delta { 'delta' }
    sub charlie { 'charlieX' }
}

{
    package AlphabetImpl;

    our %__meta__ = (
        roles => [qw( Alpha )],
    );
}

{
    package Alphabet;

    our %__meta__ = (
        interface => [qw( alpha bravo charlie delta )],
        implementation => 'AlphabetImpl',
    );
    our $Error;

    eval { Moduloop->minionize }
      or $Error = $@;
}

package main;

like($Alphabet::Error, qr|Cannot have 'charlie' in both Charlie and Delta|);

done_testing();
