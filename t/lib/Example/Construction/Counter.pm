package Example::Construction::Counter;

use Moduloop
    interface => [ qw( next ) ],

    constructor => {
        kv_args => {
            start => {
                callbacks => {
                    is_integer => sub { $_[0] =~ /^\d+$/ }
                },
            },
        }
    },
    implementation => 'Example::Construction::Acme::Counter';

1;
