package Example::Synopsis::Acme::Counter;

use strict;

our %__Meta = (
    has  => {
        count => { default => 0 },
    }, 
);

sub next {
    my ($self) = @_;

    $self->{__count}++;
}

1;