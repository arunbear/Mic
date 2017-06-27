package Example::Roles::Stack;

use Moduloop
    interface => { 
        object => {
            push => {},
            pop  => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Roles::Acme::Stack_v1',
;

1;

