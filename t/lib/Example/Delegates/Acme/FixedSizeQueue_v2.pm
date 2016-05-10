package Example::Delegates::Acme::FixedSizeQueue_v2;

use Example::Delegates::Queue;

use Moduloop::Implementation
    has  => {
        q => { 
            default => sub { Example::Delegates::Queue->new },
        },

        max_size => { 
            init_arg => 'max_size',
        },
    }, 
    forwards => [
        {
            send => 'q_size',
            to   => 'q',
            as   => 'size'
        },
        {
            send => 'q_pop',
            to   => 'q',
            as   => 'pop'
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
