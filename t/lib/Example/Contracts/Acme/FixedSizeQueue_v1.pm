package Example::Contracts::Acme::FixedSizeQueue_v1;

use Example::Delegates::Queue;

use Moduloop::Implementation
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
            send => [qw( head tail size pop )],
            to   => 'Q'
        },
    ],
;

sub push {
    my ($self, $val) = @_;

    if ($self->size == $self->{$MAX_SIZE}) {
        $self->pop;        
    }

    $self->{$Q}->push($val);
}

1;
