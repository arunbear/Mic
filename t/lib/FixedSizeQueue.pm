package FixedSizeQueue;

use strict;
use Minion;

our %__Meta = (
    interface => [qw(push size max_size)],
    implementation => 'FixedSizeQueueImpl',
    requires  => {
        max_size => { 
            assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            reader => 1,
        },
    }, 
);
Minion->minionize;
