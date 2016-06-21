use strict;
use Test::Lib;
use Test::Most;
use Moduloop
    contracts => { 'Example::Contracts::FixedSizeQueue' => { invariant => 1 } },
    bind      => { 'Example::Contracts::FixedSizeQueue' => 'Example::Contracts::Acme::FixedSizeQueue_v5' };
use Example::Contracts::FixedSizeQueue;

my $q = Example::Contracts::FixedSizeQueue->new(max_size => 3);

$q->push($_) for 1 .. 3;
is $q->size => 3;

throws_ok { $q->push($_) for 4 .. 6 } qr/Invariant 'max_size_not_exceeded' violated/;
done_testing();
