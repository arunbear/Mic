use strict;
use Test::Lib;
use Test::More;
use Moduloop
    contracts => { 'Example::Contracts::FixedSizeQueue' => { invariant => 1 } };
use Example::Contracts::FixedSizeQueue;

my $q = Example::Contracts::FixedSizeQueue->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->size => 3;

$q->push($_) for 4 .. 6;
is $q->size => 3;
is $q->pop => 4;
done_testing();
