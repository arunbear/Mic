use strict;
use Test::Lib;
use Test::More;
use Example::Delegates::MultiQueue;

my $q = Example::Delegates::MultiQueue::->new;

$q->multi_push('a');
$q->multi_push('b');

my $aref = $q->multi_pop();
is_deeply($aref, ['a', 'a']);

my @vals = $q->multi_pop();
is_deeply(\@vals, ['b', 'b']);

done_testing();
