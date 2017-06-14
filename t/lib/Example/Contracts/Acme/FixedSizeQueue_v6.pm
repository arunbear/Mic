package Example::Contracts::Acme::FixedSizeQueue_v6;

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
            send => [qw( head pop tail size )],
            to   => 'q'
        },
    ],
;

sub BUILD { 
    my (undef, $self) = @_;

    # make constructor postcondition fail
    $self->{$Q}->push(1);
}

sub push {
    my ($self, $val) = @_;

    $self->{$Q}->push($val);

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

1;
