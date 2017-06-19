package Example::Construction::Set_v1;

use Moduloop

    interface => { 
        object => {
            add => {},
            has => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Construction::Acme::Set_v1',
;

1;
