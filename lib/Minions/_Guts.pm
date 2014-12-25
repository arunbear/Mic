package Minions::_Guts;

use Digest::MD5 qw( md5_hex );

*attribute_sym = \ substr(md5_hex($$), 0 ,8);

our %obfu_name;

sub obfu_name {
    my ($name, $spec) = @_;

    if ($spec->{no_attribute_vars} || ! $obfu_name{$name}) {
        return "-$name";        
    }
    else {
        return $obfu_name{$name};
    }
}

1;
