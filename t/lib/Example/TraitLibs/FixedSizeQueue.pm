package Example::TraitLibs::FixedSizeQueue;

use Moduloop
    interface => { 
        object => {
            push => {},
            pop  => {},
            size => {},
        },
        class => { new => {} }
    },

    constructor => {
        kv_args => {
            max_size => { 
                callbacks => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            },
        }
    },

    implementation => 'Example::TraitLibs::Acme::FixedSizeQueue_v1',
;

1;
