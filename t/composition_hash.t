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
    package KeyboardImpl;
    our %__Meta = (
        has => { 
            alphabet => {
                handles => {
                    alpha => 'alpha',
                    beta  => 'bravo',
                    gamma => 'charlie',
                    delta => 'delta',
                },
                init_arg => 'alphabet' 
            }
        }
    );
}

{
    package Keyboard;

    our %__Meta = (
        interface => [qw( alpha beta gamma delta )],
        construct_with => {
            alphabet => { required => 1 },
        },
        implementation => 'KeyboardImpl',
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
