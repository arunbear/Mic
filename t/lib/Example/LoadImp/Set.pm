package Example::LoadImp::Set;

use Moduloop
    declare_interface => { 
        object => {
            add => {},
            has => {},
        },
        class => { new => {} }
    };
1;
