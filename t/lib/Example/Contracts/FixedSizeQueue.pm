package Example::Contracts::FixedSizeQueue;

use Moduloop
    interface => {
        push => {
            ensure => {
                size_increased => sub {
                    my ($self, $old) = @_;
                    $self->size == $old->size + 1;
                },
            }
        },

        pop => {
            require => {
                not_empty => sub {
                    my ($self) = @_;
                    $self->size > 0;
                },
            }
        },

        size => {},
    },

    constructor => {
        kv_args => {
            max_size => { 
                callbacks => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            },
        }
    },

    implementation => 'Example::Delegates::Acme::FixedSizeQueue_v1',
;

1;
