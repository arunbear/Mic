use strict;
use Test::Lib;
use Test::Most;
use Moduloop ();

{
    package SorterTraits;

    use Moduloop::Role
        semiprivate => ['cmp'],
        requires    => ['cmp']
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
        roles => [ 'SorterTraits' ],
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
        interface => { 
            object => {
                sort => {},
            },
            class => { new => {} }
        },
        implementation => 'SorterImpl',
    ;
}

package main;

my $sorter = Sorter->new;

is_deeply($sorter->sort([1 .. 4]), [4,3,2,1], 'required method present.');
ok(! $sorter->can('cmp'), "Can't call private sub");

done_testing();
