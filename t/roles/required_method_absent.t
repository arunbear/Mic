use strict;
use Test::Lib;
use Test::Most;

{
    package SorterTraits;

    use Moduloop::Role
        requires => ['cmp']
    ;

    sub sort {
        my ($self, $items) = @_;
        my $cmp = sub { $self->cmp(@_) };
        return sort $cmp @$items;
    }
}

{
    package SorterImpl;

    use Moduloop::Implementation
        roles => [ 'SorterTraits' ],
    ;
}

{
    package Sorter;
    use Moduloop ();

    eval { 
        Moduloop->assemble({
            interface => { 
                object => {
                    sort => {},
                },
                class => { new => {} }
            },
            implementation => 'SorterImpl',
        });
    }
      or our $Error = $@;
}

package main;

like($Sorter::Error, qr/Method 'cmp', required by role SorterTraits, is not implemented./);

done_testing();
