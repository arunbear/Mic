use strict;
use Test::Lib;
use Test::Most;
use Minion;

{
    package SorterRole;

    our %__Meta = (
        role => 1,
        requires => { methods => ['cmp'] }
    );

    sub sort {
        my ($self, $items) = @_;
        
        my $cmp = $self->{'!'}->can('cmp');
        return [ sort $cmp @$items ];
    }
}

{
    package SorterImpl;

    our %__Meta = (
    );

    # private sub
    sub cmp {
        my ($x, $y) = @_;
        $y <=> $x;    
    }
}

{
    package Sorter;

    our %__Meta = (
        interface => [qw( sort )],
        implementation => 'SorterImpl',
        roles => [qw( SorterRole )],
    );
    Minion->minionize;
}

package main;

my $sorter = Sorter->new;

is_deeply($sorter->sort([1 .. 4]), [4,3,2,1], 'required method present.');
ok(! $sorter->can('cmp'), "Can't call private sub");

done_testing();
