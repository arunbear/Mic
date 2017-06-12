use strict;
use Test::Lib;
use Test::More;
use Moduloop
    bind => { 'Example::Delegates::FixedSizeQueue' => 'Example::ArrayImps::FixedSizeQueueImp' };

use Example::Delegates::FixedSizeQueue;

my $q = Example::Delegates::FixedSizeQueue->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->size => 3;

$q->push($_) for 4 .. 6;
is $q->size => 3;
is $q->pop => 4;
done_testing();
