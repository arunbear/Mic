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

    use Moduloop
        interface => [qw( alpha bravo charlie delta )],
        implementation => 'AlphabetImpl',
    ;
}

package main;

my $ab = Alphabet->new;
can_ok($ab, qw( alpha bravo charlie delta ));
is($ab->alpha,   'alpha');
is($ab->bravo,   'bravo');
is($ab->charlie, 'charlie');
is($ab->delta,   'delta');

ok($ab->DOES('UNIVERSAL'),  'does UNIVERSAL');
ok($ab->DOES('Alphabet'),   'does Alphabet');
ok($ab->DOES('Alpha'),   'does Alpha role');
ok($ab->DOES('Bravo'),   'does Bravo role');
ok($ab->DOES('Charlie'), 'does Charlie role');
ok($ab->DOES('Delta'),   'does Delta role');

is_deeply([ $ab->DOES ], [qw( Alphabet Alpha Bravo Charlie Delta )], 'DOES roles');

ok((ref $ab)->DOES('Alpha'),   'does Alpha role');
ok((ref $ab)->DOES('Bravo'),   'does Bravo role');
ok((ref $ab)->DOES('Charlie'), 'does Charlie role');
ok((ref $ab)->DOES('Delta'),   'does Delta role');

done_testing();
