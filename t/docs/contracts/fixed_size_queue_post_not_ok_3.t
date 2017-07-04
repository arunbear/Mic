use strict;
use Test::Lib;
use Test::Most;
use Moduloop
    contracts => { 'Example::Contracts::FixedSizeQueue' => { post => 1 } },
    bind      => { 'Example::Contracts::FixedSizeQueue' => 'Example::Contracts::Acme::FixedSizeQueue_v4' };
use Example::Contracts::FixedSizeQueue;

my $q = Example::Contracts::FixedSizeQueue::->new({max_size => 3});

throws_ok { $q->push(1) } qr/Method 'push' failed postcondition 'tail_updated'/;
done_testing();
