package Example::Usage::HashSet;

use strict;

our %__Meta = (
    has => { set => { default => sub { {} }, reader => 1 } },
);

sub has {
    my ($self, $e) = @_;
    exists $self->{$$}{set}{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->{$$}{set}{$e};
}

1;
