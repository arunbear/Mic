package Example::Delegates::Acme::MultiQueue;

use Example::Delegates::Queue;

use Mic::Implementation
    has  => {
        Q1 => { 
            default => sub { Example::Delegates::Queue::->new },
        },
        Q2 => { 
            default => sub { Example::Delegates::Queue::->new },
        },
    }, 
    forwards => [
        {
            send => 'multi_push',
            to   => [qw( Q1 Q2 )],
            as   => [qw( push push )]
        },
        {
            send => 'multi_pop',
            to   => [qw( Q1 Q2 )],
            as   => [qw( pop pop )]
        },
    ],
;

1;
