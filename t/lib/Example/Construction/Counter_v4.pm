package Example::Construction::Counter_v4;

use Mic::Class
    interface => { 
        object => {
            next => {},
        },
        class => { new => {} }
    },

    constructor => { 
        kv_args => {
            start => {
                callbacks => {
                    is_integer => sub { $_[0] =~ /^\d+$/ }
                },
            },
        }
    },
    implementation => 'Example::Construction::Acme::Counter_v2';

1;
