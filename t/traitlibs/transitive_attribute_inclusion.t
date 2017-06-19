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
                attributes => [qw( CHARLIE )],
            },
        },
        has => { ALPHA => { default => 'alpha' } }
    ;
    sub all_attr_vals { ( $ALPHA, $BRAVO, $CHARLIE, $DELTA ) }
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
    sub all_attr_vals { ( $BRAVO, $DELTA ) }
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

    sub all_attr_vals { ( $ALPHA, $BRAVO, $CHARLIE, $DELTA ) }
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

is_deeply(
    $ab->as_hash,
    {
        "cb5ae176-"        => "Alphabet::__Private",
        "cb5ae176-ALPHA"   => "alpha",
        "cb5ae176-BRAVO"   => "bravo",
        "cb5ae176-CHARLIE" => "charlie",
        "cb5ae176-DELTA"   => "delta",
    },
    'has attributes'
);

done_testing();
