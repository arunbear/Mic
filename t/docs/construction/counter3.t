use strict;
use Test::Lib;
use Test::Most tests => 4;
use Example::Construction::Counter_v3;

my $counter = Example::Construction::Counter_v3->new(10);

is $counter->next => 10;
is $counter->next => 11;
is $counter->next => 12;

throws_ok { Example::Construction::Counter_v3->new('abc') } 
          qr/The 'start' parameter \Q("abc")\E to Example::Construction::Counter_v3::__Util::assert did not pass the 'is_integer' callback/;
