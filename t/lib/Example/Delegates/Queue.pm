package Example::Delegates::Queue;

use Moduloop
    interface => { 
        object => {
            push => {},
            pop  => {},
            head => {},
            tail => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Delegates::Acme::Queue_v1',
;

1;
