package FixedSizeQueueImpl;

use strict;

our %__Meta = (
    has  => {
        q => { default => sub { [ ] } },
    }, 
);

sub size {
    my ($self) = @_;
    scalar @{ $self->{__q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{__q} }, $val;
}

1;
