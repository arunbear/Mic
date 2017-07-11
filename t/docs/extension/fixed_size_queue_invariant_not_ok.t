use strict;
use Test::Lib;
use Test::Most;
use Moduloop
    contracts => { 'Example::Extension::FixedSizeQueue' => { invariant => 1 } },
    bind      => { 'Example::Extension::FixedSizeQueue' => 'Example::Contracts::Acme::FixedSizeQueue_v5' };
use Example::Extension::FixedSizeQueue;

my $q = Example::Extension::FixedSizeQueue::->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->size => 3;

throws_ok { $q->push($_) for 4 .. 6 } qr/Invariant 'max_size_not_exceeded' violated/;

my @interfaces = qw/
    Example::Extension::FixedSizeQueue
    Example::Extension::Queue
/;
foreach my $i (@interfaces) {
    ok $q->DOES($i), "DOES $i";
}
is_deeply([$q->DOES], [@interfaces], 'does all');

done_testing();
