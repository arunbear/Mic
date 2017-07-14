package FixedSizeQueueImplWithRole;

use Moduloop::Implementation
    roles => ['FixedSizeQueueRole'],
    has  => {
        max_size => { 
            init_arg => 'max_size',
            reader => 1,
        },
    }, 
;

1;
