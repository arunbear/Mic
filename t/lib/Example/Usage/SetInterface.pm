package Example::Usage::SetInterface;

use Mic
    declare_interface => { 
        object => {
            add => {},
            has => {},
        },
        class => { new => {} }
    };
1;
