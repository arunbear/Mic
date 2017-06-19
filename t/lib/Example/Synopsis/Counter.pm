package Example::Synopsis::Counter;

use Moduloop
    interface => { 
        object => {
            next => {},
        },
        class => { new => {} }
    },
    implementation => 'Example::Synopsis::Acme::Counter';

1;
