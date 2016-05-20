use strict;
use Test::Lib;
use Test::More;

use Moduloop
    bind => { 
        'Example::TraitLibs::FixedSizeQueue' => 'Example::TraitLibs::Acme::FixedSizeQueue_v3' 
    };
use Example::TraitLibs::FixedSizeQueue;

my $q = Example::TraitLibs::FixedSizeQueue->new(max_size => 3);

$q->push($_) for 1 .. 3;
is $q->size => 3;

$q->push($_) for 4 .. 6;
is $q->size => 3;
is $q->pop => 4;
done_testing();
