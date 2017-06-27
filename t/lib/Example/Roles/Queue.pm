package Example::Roles::Queue; 

use Moduloop
    interface => { 
        object => {
            push => {},
            pop  => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Roles::Acme::Queue_v1',
;

1;
