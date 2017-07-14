use strict;
use Test::Lib;
use Test::More;
use Moduloop
    bind => { 'Example::Delegates::BoundedQueue_v2' => 'Example::Delegates::Acme::BoundedQueue_v3' };
use Example::Delegates::BoundedQueue_v2;

my $q = Example::Delegates::BoundedQueue_v2::->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->q_size => 3;

$q->push($_) for 4 .. 6;
is $q->q_size => 3;
is $q->q_pop => 4;
done_testing();
