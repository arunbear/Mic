
package Example::Construction::Acme::Set_v1;

use strict;

our %__Meta = (
    has => { set => { default => sub { {} } } },
);

sub has {
    my ($self, $e) = @_;
    exists $self->{__set}{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->{__set}{$e};
}

1;