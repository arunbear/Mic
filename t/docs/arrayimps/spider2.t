use strict;
use Scalar::Util qw( reftype );
use Test::Lib;
use Test::More tests => 1;

use Example::ArrayImps::Spider_v2;

my $spider = Example::ArrayImps::Spider_v2::->new;

$spider->url = 'http://example.com';
my $msg = $spider->crawl;
is $msg, 'Crawling over http://example.com';
