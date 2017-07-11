package Example::Extension::Queue;

use Moduloop
    declare_interface => { 
        object => {
            push => {},
            pop  => {},
            head => {},
            tail => {},
            size => {},
        },
        class => { new => {} }
    };

1;
