package Example::TraitLibs::Queue;

use Moduloop
    interface => { 
        object => {
            push => {},
            pop  => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::TraitLibs::Acme::Queue_v1',
;

1;
