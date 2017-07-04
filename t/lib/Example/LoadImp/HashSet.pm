package Example::LoadImp::HashSet;

use Moduloop::Implementation

    has => { SET => { default => sub { {} } } },
;

sub has {
    my ($self, $e) = @_;
    exists $self->{$SET}{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->{$SET}{$e};
}

1;
