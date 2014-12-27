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
    exists $self->{$__set}{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->{$__set}{$e};
}

1;
