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
}

{
    package Alphabet;

    our %__Meta = (
        interface => [qw( alpha bravo charlie delta )],
        roles => [qw( Alpha )],
    );
    Minion->minionize;
}

package main;

my $ab = Alphabet->new;
can_ok($ab, qw( alpha bravo charlie delta ));
is($ab->alpha,   'alpha');
is($ab->bravo,   'bravo');
is($ab->charlie, 'charlie');
is($ab->delta,   'delta');

done_testing();
