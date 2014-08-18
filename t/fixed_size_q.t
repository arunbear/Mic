use strict;
use Test::More;
use Minion;

package FixedSizeQueue;

our %__Meta = (
    interface => [qw(push size max_size)],
    implementation => 'FixedSizeQueueImpl',
    has  => {
        max_size => { 
            assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            reader => 1,
        },
    }, 
);
Minion->minionize;

package main;

my $q = FixedSizeQueue->new(max_size => 3);

is($q->max_size, 3);

#$q->push(1);
#is($q->size, 1);
done_testing();
