package Example::Construction::Acme::Set_v1;

use strict;

our %__Meta = (
    has => { 
        set => { 
            default => sub { {} },
            init_arg => 'items',
        } 
    },
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
