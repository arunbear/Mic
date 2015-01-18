package Example::Delegates::Acme::FixedSizeQueue_v1;

use Example::Delegates::Queue;

use Minions::Implementation
    has  => {
        q => { 
            default => sub { Example::Delegates::Queue->new },

            handles => [qw( size pop )],
        },

        max_size => { 
            init_arg => 'max_size',
        },
    }, 
;

sub push {
    my ($self, $val) = @_;

    $self->{$__q}->push($val);

    if ($self->size > $self->{$__max_size}) {
        $self->pop;        
    }
}

1;
