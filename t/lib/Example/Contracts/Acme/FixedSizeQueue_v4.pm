package Example::Contracts::Acme::FixedSizeQueue_v4;

use Example::Delegates::Queue;

use Moduloop::Implementation
    has  => {
        q => { 
            default => sub { Example::Delegates::Queue->new },
        },

        max_size => { 
            init_arg => 'max_size',
            reader   => 'max_size',
        },
    }, 
    forwards => [
        {
            send => [qw( head size pop )],
            to   => 'q'
        },
    ],
;

sub tail { 
    my ($self) = @_;

    # make postcondition fail
    \ $self->{$Q}->tail;
}

sub push {
    my ($self, $val) = @_;

    $self->{$Q}->push($val);

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

1;
