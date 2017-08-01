use strict;
use Test::Lib;
use Test::Most;
use Mic::Contracts 'Example::Extension::BoundedQueue_v2' => { invariant => 1 };
use Mic::Bind      'Example::Extension::BoundedQueue_v2' => 'Example::Contracts::Acme::BoundedQueue_v5';
use Example::Extension::BoundedQueue_v2;

my $q = Example::Extension::BoundedQueue_v2::->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->size => 3;

throws_ok { $q->push($_) for 4 .. 6 } qr/Invariant 'max_size_not_exceeded' violated/;

my @interfaces = qw/
    Example::Extension::BoundedQueue_v2
    Example::Delegates::Queue
/;
foreach my $i (@interfaces) {
    ok $q->DOES($i), "DOES $i";
}
is_deeply([$q->DOES], [@interfaces], 'does all');

done_testing();
