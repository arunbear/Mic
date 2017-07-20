package Example::Construction::Counter;

use Mic
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
    implementation => 'Example::Construction::Acme::Counter';

1;
