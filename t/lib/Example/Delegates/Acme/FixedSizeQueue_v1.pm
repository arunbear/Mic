package Example::Delegates::Acme::FixedSizeQueue_v1;

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
            send => [qw( size pop )],
            to   => 'q'
        },
    ],
;

sub push {
    my ($self, $val) = @_;

    $self->{$Q}->push($val);

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

1;
