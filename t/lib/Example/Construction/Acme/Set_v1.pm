package Example::Construction::Acme::Set_v1;

use Minions::Implementation
    has => { 
        set => { 
            default => sub { {} },
            init_arg => 'items',
            map_init_arg => sub { return { map { $_ => 1 } @{ $_[0] } } },
        } 
    },
;

sub has {
    my ($self, $e) = @_;

    log_info($self);
    exists $self->{$__set}{$e};
}

sub add {
    my ($self, $e) = @_;

    log_info($self);
    ++$self->{$__set}{$e};
}

sub log_info {
    my ($self) = @_;

    warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
}

sub size {
    my ($self) = @_;
    scalar(keys %{ $self->{$__set} });
}

1;
