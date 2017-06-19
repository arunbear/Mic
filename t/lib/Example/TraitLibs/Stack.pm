package Example::TraitLibs::Stack;

use Moduloop
    interface => { 
        object => {
            push => {},
            pop  => {},
            size => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::TraitLibs::Acme::Stack_v1',
;

1;

