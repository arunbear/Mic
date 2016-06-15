package Example::Contracts::FixedSizeQueue;

use Moduloop
    interface => {
        push => {},
        pop => {},
        size => {},
    },

    constructor => {
        kv_args => {
            max_size => { 
                callbacks => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            },
        }
    },

    implementation => 'Example::Delegates::Acme::FixedSizeQueue_v1',
;

1;
