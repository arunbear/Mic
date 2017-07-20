package Example::Construction::Set_v1;

use Mic

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
