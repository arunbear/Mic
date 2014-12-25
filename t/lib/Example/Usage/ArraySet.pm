package Example::Usage::ArraySet;

use Minions::Implementation
    has => { set => { default => sub { [] } } },
;

sub has {
    my ($self, $e) = @_;
    scalar grep { $_ == $e } @{ $self->{$__Set} };
}

sub add {
    my ($self, $e) = @_;

    if ( ! $self->has($e) ) {
        push @{ $self->{$__Set} }, $e;
    }
}

1;
