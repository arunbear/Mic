package Example::Usage::SetInterface;

use Moduloop
    declare_interface => { 
        object => {
            add => {},
            has => {},
        },
        class => { new => {} }
    };
1;
