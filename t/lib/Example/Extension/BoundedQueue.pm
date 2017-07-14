package Example::Extension::BoundedQueue;

use Moduloop
    interface => { 
        extends => [qw/Example::Extension::Queue/],

        object => {
            max_size => {},
        },

        invariant => {
            max_size_not_exceeded => sub {
                my ($self) = @_;
                $self->size <= $self->max_size;
            },
        },
    },

    implementation => 'Example::Delegates::Acme::BoundedQueue_v1',
;

1;
