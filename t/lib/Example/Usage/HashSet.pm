package Example::Usage::HashSet;

use Minions::Implementation
    has => { set => { default => sub { {} } } },
;

sub has {
    my ($self, $e) = @_;
    exists $self->{$__Set}{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->{$__Set}{$e};
}

1;
