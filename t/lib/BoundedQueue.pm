package BoundedQueue;

use strict;
use Moduloop ();

our %__meta__ = (
    interface => { 
        object => {
            push => {},
            size => {},
            max_size => {},
        },
        class => { new => {} }
    },
    implementation => 'BoundedQueueImpl',
    construct_with  => {
        max_size => { 
            assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
        },
    }, 
);
Moduloop->minionize;
