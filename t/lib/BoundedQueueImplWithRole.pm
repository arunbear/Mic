package BoundedQueueImplWithRole;

use Moduloop::Implementation
    roles => ['BoundedQueueRole'],
    has  => {
        max_size => { 
            init_arg => 'max_size',
            reader => 1,
        },
    }, 
;

1;
