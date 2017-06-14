package Example::Contracts::FixedSizeQueue;

use Moduloop
    interface => {
        class => {
            new => {
                ensure => {
                    zero_sized => sub {
                        my ($obj) = @_;
                        $obj->size == 0;
                    },
                }
            },
        },
        object => {
            head => {},
            tail => {},
            size => {},
            max_size => {},

            push => {
                ensure => {
                    size_increased => sub {
                        my ($self, $old) = @_;

                        return $self->size < $self->max_size
                          ? $self->size == $old->size + 1
                          : 1;
                    },
                    tail_updated => sub {
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
    },

    invariant => {
        max_size_not_exceeded => sub {
            my ($self) = @_;
            $self->size <= $self->max_size;
        },
    },

    constructor => {
        kv_args => {
            max_size => { 
                callbacks => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            },
        },
    },

    implementation => 'Example::Contracts::Acme::FixedSizeQueue_v1',
;

1;
