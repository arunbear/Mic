package Example::LoadImp::Set;

use Mic
    declare_interface => { 
        object => {
            add => {},
            has => {},
        },
        class => { new => {} }
    };
1;
