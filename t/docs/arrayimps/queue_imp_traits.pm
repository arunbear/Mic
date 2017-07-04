use strict;
use Test::Lib;
use Test::More;
use Moduloop
    bind => { 'Example::Delegates::Queue' => 'Example::ArrayImps::QueueImp' };

use Example::Delegates::Queue;

my $q = Example::Delegates::Queue::->new;

$q->push($_) for 1 .. 3;
is $q->size => 3;
done_testing();
