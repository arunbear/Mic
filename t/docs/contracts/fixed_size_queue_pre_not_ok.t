use strict;
use Test::Lib;
use Test::Most;
use Moduloop
    contracts => { 'Example::Contracts::FixedSizeQueue' => { pre => 1 } };
use Example::Contracts::FixedSizeQueue;

my $q = Example::Contracts::FixedSizeQueue->new({max_size => 3});

is $q->size => 0, 'is empty';
throws_ok { $q->pop } qr/Method 'pop' failed precondition 'not_empty'/;
done_testing();
