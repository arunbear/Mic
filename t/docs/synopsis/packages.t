use strict;
use Test::Lib;
use Test::Most tests => 3;
use Example::Synopsis::Counter;

my $counter = Example::Synopsis::Counter->new;

is $counter->next => 0;
is $counter->next => 1;
is $counter->next => 2;