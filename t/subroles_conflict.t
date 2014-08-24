use strict;
use Test::Lib;
use Test::Most;
use Minion;

{
    package Alpha;

    our %__Meta = (
        role => 1,
        roles => [qw( Bravo Charlie )]
    );

    sub alpha { 'alpha' }
}

{
    package Bravo;

    our %__Meta = (
        role => 1,
        roles => [qw( Delta )]
    );

    sub bravo { 'bravo' }
}

{
    package Charlie;

    our %__Meta = (
        role => 1,
    );

    sub charlie { 'charlie' }
}

{
    package Delta;

    our %__Meta = (
        role => 1,
    );

    sub delta { 'delta' }
    sub charlie { 'charlieX' }
}

{
    package Alphabet;

    our %__Meta = (
        interface => [qw( alpha bravo charlie delta )],
        roles => [qw( Alpha )],
    );
    our $Error;

    eval { Minion->minionize }
      or $Error = $@;
}

package main;

like($Alphabet::Error, qr|Cannot have 'charlie' in both Charlie and Delta|);

done_testing();
