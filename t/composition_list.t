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
        requires => {
            code => {
                assert => { 'valid code' => sub { $_[0] eq 'en' } },
                attribute => 1,
            },
        }
    );
    Minion->minionize;
}

{
    package Keyboard;

    our %__Meta = (
        interface => [qw( alpha bravo charlie delta )],
        requires => {
            alphabet => {
                handles => [qw( alpha bravo charlie delta )],
                assert => { 'isa Alphabet' => sub { $_[0]->isa('Alphabet::__Minion') } },
                attribute => 1,
            },
        },
    );
    Minion->minionize();
}

package main;

my $kb = Keyboard->new(alphabet => Alphabet->new(code=>'en'));
can_ok($kb, qw( alpha bravo charlie delta ));
is($kb->alpha,   'alpha');
is($kb->bravo,   'bravo');
is($kb->charlie, 'charlie');
is($kb->delta,   'delta');

done_testing();
