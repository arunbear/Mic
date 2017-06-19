package Example::Delegates::MultiQueue;

use Moduloop
    interface => { 
        object => {
            multi_push => {},
            multi_pop  => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Delegates::Acme::MultiQueue',
;

1;
