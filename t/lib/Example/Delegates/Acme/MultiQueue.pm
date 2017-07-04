package Example::Delegates::Acme::MultiQueue;

use Example::Delegates::Queue;

use Moduloop::Implementation
    has  => {
        q1 => { 
            default => sub { Example::Delegates::Queue::->new },
        },
        q2 => { 
            default => sub { Example::Delegates::Queue::->new },
        },
    }, 
    forwards => [
        {
            send => 'multi_push',
            to   => [qw( q1 q2 )],
            as   => [qw( push push )]
        },
        {
            send => 'multi_pop',
            to   => [qw( q1 q2 )],
            as   => [qw( pop pop )]
        },
    ],
;

1;
