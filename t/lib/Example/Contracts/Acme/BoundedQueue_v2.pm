package Example::Contracts::Acme::BoundedQueue_v2;

use Example::Delegates::Queue;

use Mic::Implementation
    has  => {
        Q => {
            default => sub { Example::Delegates::Queue::->new },
        },

        MAX_SIZE => {
            init_arg => 'max_size',
            reader   => 'max_size',
        },
    }, 
    forwards => [
        {
            send => [qw( head tail size )],
            to   => 'Q'
        },
    ],
;

sub pop { 
    my ($self) = @_;

    # make postcondition fail
    $self->{$Q}->pop + 1;
}

sub push {
    my ($self, $val) = @_;

    $self->{$Q}->push($val);

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

1;
