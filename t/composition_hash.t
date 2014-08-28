use strict;
use Test::Lib;
use Test::Most;
use AlphabetRole;
use Minion;

{
    package Alphabet;

    our %__Meta = (
        interface => [qw( alpha bravo charlie delta )],
        roles => [qw( AlphabetRole )],
    );
    Minion->minionize;
}

{
    package Keyboard;

    our %__Meta = (
        interface => [qw( alpha beta gamma delta )],
        requires => {
            alphabet => {
                handles => {
                    alpha => 'alpha',
                    beta  => 'bravo',
                    gamma => 'charlie',
                    delta => 'delta',
                },
            },
        },
    );
    Minion->minionize;
}

package main;

my $kb = Keyboard->new(alphabet => Alphabet->new);

can_ok($kb, qw( alpha beta gamma delta ));

is($kb->alpha, 'alpha');
is($kb->beta,  'bravo');
is($kb->gamma, 'charlie');
is($kb->delta, 'delta');

done_testing();
