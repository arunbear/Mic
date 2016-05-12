package Example::Roles::Acme::FixedSizeQueue_v2;

use Moduloop::Implementation
    has  => {
        max_size => { 
            init_arg => 'max_size',
        },
    }, 
    semiprivate => ['after_push'],
    traits => {
        Example::Roles::Role::Queue => {
            methods    => [qw( push pop size )],
            attributes => ['q']
        }
    },
;

sub after_push {
    my (undef, $self) = @_;

    if ($self->size > $self->{$MAX_SIZE}) {
        $self->pop;        
    }
}

1;
