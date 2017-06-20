package Example::Construction::Counter_v3;

use strict;
use Moduloop
    interface => { 
        object => {
            next => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Construction::Acme::CounterWithNew';

1;
