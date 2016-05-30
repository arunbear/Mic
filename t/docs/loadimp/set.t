use strict;
use Test::Lib;
use Test::More tests => 4;
use Example::LoadImp::Set;

my $HashSetClass  = Example::LoadImp::Set->load_imp('Example::LoadImp::HashSet');
my $ArraySetClass = Example::LoadImp::Set->load_imp('Example::LoadImp::ArraySet');

my $a_set = $ArraySetClass->new;
ok ! $a_set->has(1);
$a_set->add(1);
ok $a_set->has(1);
diag explain $a_set;

my $h_set = $HashSetClass->new;
ok ! $h_set->has(1);
$h_set->add(1);
ok $h_set->has(1);
diag explain $h_set;
