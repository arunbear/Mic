use strict;
use Test::Lib;
use Test::More;
use Test::Output;

use Moduloop
    bind => {
        'Example::TraitLibs::Queue' => 'Example::TraitLibs::Acme::Queue_v3',
    };
use Example::TraitLibs::Queue;

my $q = Example::TraitLibs::Queue->new;

$q->push(1);

my $item;
stderr_like(sub { $item = $q->pop }, qr'I have 1 element');
is($item, 1, 'pop');

done_testing();
