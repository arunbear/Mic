package Example::Roles::FixedSizeQueue;

use Moduloop
    interface => { 
        object => {
            push => {},
            pop  => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Roles::Acme::FixedSizeQueue_v1',
; 
1;
