package Example::Usage::HashSet;

use Minions::Implementation
    has => { set => { default => sub { {} } } },
;

sub has {
    my ($self, $e) = @_;
    exists $self->{-set}{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->{-set}{$e};
}

1;
