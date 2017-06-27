use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package Alpha;

    use Moduloop::Role
        roles => [qw( Bravo Charlie )],
    ;

    sub alpha { 'alpha' }
}

{
    package Bravo;

    use Moduloop::Role
        roles => [qw( Delta )],
    ;

    sub bravo { 'bravo' }
}

{
    package Charlie;

    use Moduloop::Role;

    sub charliex { 'charlie' }
}

{
    package Delta;

    use Moduloop::Role;

    sub delta { 'delta' }
}

{
    package AlphabetImpl;

    use Moduloop::Implementation
        roles => [qw( Alpha )],
    ;
}

{
    package Alphabet;

    use Moduloop ();
    eval { 
        Moduloop->assemble({
            interface => { 
                object => {
                    alpha   => {},
                    bravo   => {},
                    charlie => {},
                    delta   => {},
                },
                class => { new => {} }
            },
            implementation => 'AlphabetImpl',
        });
    }
      or our $Error = $@;
}

package main;

like($Alphabet::Error, qr/Interface method 'charlie' is not implemented/);

done_testing();
