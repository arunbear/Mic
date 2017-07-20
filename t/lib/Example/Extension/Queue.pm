package Example::Extension::Queue;

use Mic
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
