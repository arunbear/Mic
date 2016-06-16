package Example::Contracts::FixedSizeQueue;

use Moduloop
    interface => {
        head => {},
        tail => {},
        size => {},

        push => {
            ensure => {
                size_increased => sub {
                    my ($self, $old) = @_;
                    $self->size == $old->size + 1;
                },
                size_increased => sub {
                    my ($self, $old, $results, $item) = @_;
                    $self->tail == $item;
                },
            }
        },

        pop => {
            require => {
                not_empty => sub {
                    my ($self) = @_;
                    $self->size > 0;
                },
            },
            ensure => {
                returns_old_head => sub {
                    my ($self, $old, $results) = @_;
                    $results->[0] == $old->head;
                },
            }
        },
    },

    constructor => {
        kv_args => {
            max_size => { 
                callbacks => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            },
        }
    },

    implementation => 'Example::Contracts::Acme::FixedSizeQueue_v1',
;

1;
