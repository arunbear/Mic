use strict;
use Test::Lib;
use Test::Most;

{
    package SorterTraits;

    use Moduloop::TraitLib
        requires => { methods => ['cmp'] }
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
        traits => {
            SorterTraits => {
                methods => [qw( sort )],
            },
        },
    ;
}

{
    package Sorter;
    use Moduloop ();

    eval { 
        Moduloop->assemble({
            interface => [qw( sort )],
            implementation => 'SorterImpl',
        });
    }
      or our $Error = $@;
}

package main;

like($Sorter::Error, qr/Method 'cmp', required by traitlib SorterTraits, is not implemented./);

done_testing();
