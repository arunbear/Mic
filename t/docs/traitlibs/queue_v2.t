use strict;
use Test::Lib;
use Test::More;

use Moduloop
    bind => {
        'Example::TraitLibs::Queue' => 'Example::TraitLibs::Acme::Queue_v2',
    };
use Example::TraitLibs::Queue;

my $q = Example::TraitLibs::Queue->new;

is $q->size => 0;

$q->push(1);
is $q->size => 1;

$q->push(2);
is $q->size => 2;

my $n = $q->pop;
is $n => 1;
is $q->size => 1;
done_testing();
