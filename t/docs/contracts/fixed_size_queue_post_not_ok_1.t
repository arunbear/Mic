use strict;
use Test::Lib;
use Test::Most;
use Moduloop
    contracts => { 'Example::Contracts::FixedSizeQueue' => { post => 1 } },
    bind      => { 'Example::Contracts::FixedSizeQueue' => 'Example::Contracts::Acme::FixedSizeQueue_v2' };
use Example::Contracts::FixedSizeQueue;

my $q = Example::Contracts::FixedSizeQueue::->new({max_size => 3});

$q->push(1);
is $q->size => 1, 'non empty';
throws_ok { $q->pop } qr/Method 'pop' failed postcondition 'returns_old_head'/;
done_testing();
