use strict;
use Test::Lib;
use Test::More;
use Example::TraitLibs::Stack;

my $s = Example::TraitLibs::Stack->new;

is $s->size => 0;

$s->push(1);
is $s->size => 1;

$s->push(2);
is $s->size => 2;

my $n = $s->pop;
is $n => 2;
is $s->size => 1;
done_testing();
