use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package SorterTraits;

    use Moduloop::TraitLib
        semiprivate => ['cmp'],
        requires    => { methods => ['cmp'] }
    ;

    sub sort {
        my ($self, $items) = @_;
        
        my $cmp = $self->{$__}->can('cmp');
        return [ sort $cmp @$items ];
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
        semiprivate => ['cmp'],
    ;

    sub cmp ($$) {
        my ($x, $y) = @_;
        $y <=> $x;    
    }
}

{
    package Sorter;

    use Moduloop
        interface => [qw( sort )],
        implementation => 'SorterImpl',
    ;
}

package main;

my $sorter = Sorter->new;

is_deeply($sorter->sort([1 .. 4]), [4,3,2,1], 'required method present.');
ok(! $sorter->can('cmp'), "Can't call private sub");

done_testing();
