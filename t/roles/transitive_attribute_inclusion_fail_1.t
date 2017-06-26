use strict;
use Test::Lib;
use Test::Most;

{
    package Alpha;

    use Moduloop::TraitLib
        traits => {
            Bravo => {
                attributes => [qw( BRAVO DELTA )],
            },
            Charlie => {
                attributes => [qw( CHARLIEX )],
            },
        },
        has => { ALPHA => { default => 'alpha' } }
    ;
}

{
    package Bravo;

    use Moduloop::TraitLib
        traits => {
            Delta => {
                attributes => [qw( DELTA )],
            },
        },
        has => { BRAVO => { default => 'bravo' } }
    ;
}

{
    package Charlie;

    use Moduloop::TraitLib
        has => { CHARLIE => { default => 'charlie' } }
    ;
}

{
    package Delta;

    use Moduloop::TraitLib
        has => { DELTA => { default => 'delta' } }
    ;
}

{
    package AlphabetImpl;

    use Moduloop::Implementation
        traits => {
            Alpha => {
                attributes => [qw( ALPHA BRAVO CHARLIE DELTA )],
            },
        },
        version => 0.1,
    ;

    sub as_hash { $_[0] }
}

{
    package Alphabet;

    use Moduloop
        interface => { 
            object => {
                as_hash => {},
            },
            class => { new => {} }
        },
        implementation => 'AlphabetImpl',
    ;
}

package main;

my $ab = Alphabet->new;

ok(! exists $ab->{"cb5ae176-CHARLIE"}, 'excluded attribute');

is_deeply(
    $ab->as_hash,
    {
        "cb5ae176-"        => "Alphabet::__Private",
        "cb5ae176-ALPHA"   => "alpha",
        "cb5ae176-BRAVO"   => "bravo",
        "cb5ae176-DELTA"   => "delta",
    },
    'has included attributes'
);

done_testing();
