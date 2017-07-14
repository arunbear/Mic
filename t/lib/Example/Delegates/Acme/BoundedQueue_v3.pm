package Example::Delegates::Acme::BoundedQueue_v3;

use Example::Delegates::Queue;

use Moduloop::Implementation
    has  => {
        Q => { 
            default => sub { Example::Delegates::Queue::->new },
        },

        MAX_SIZE => { 
            init_arg => 'max_size',
        },
    }, 
    forwards => [
        {
            send => [qw( q_size q_pop )],
            to   => 'Q',
            as   => [qw( size pop )],
        },
    ],
;

sub push {
    my ($self, $val) = @_;

    $self->{$Q}->push($val);

    if ($self->q_size > $self->{$MAX_SIZE}) {
        $self->q_pop;        
    }
}

1;
