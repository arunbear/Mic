use strict;
use Test::Lib;
use Test::Most;
use Moduloop
    contracts => { 'Example::Contracts::FixedSizeQueue' => { post => 1 } },
    bind      => { 'Example::Contracts::FixedSizeQueue' => 'Example::Contracts::Acme::FixedSizeQueue_v6' };
use Example::Contracts::FixedSizeQueue;

throws_ok { 
    my $q = Example::Contracts::FixedSizeQueue::->new({max_size => 3});
} 
qr/Method 'new' failed postcondition 'zero_sized'/;
done_testing();
