package Example::Delegates::BoundedQueue_v2;

use Mic
    interface => { 
        object => {
            push  => {},
            q_pop => {},
            q_size => {},
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

    implementation => 'Example::Delegates::Acme::BoundedQueue_v2',
;

1;