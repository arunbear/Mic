package Minions::_Guts;

use Digest::MD5 qw( md5_hex );

*attribute_sym = \ substr(md5_hex($$), 0 ,8);

1;
