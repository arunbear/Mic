package Example::Usage::HashSet;

use Minions::Implementation
    has => { set => { default => sub { {} } } },
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
