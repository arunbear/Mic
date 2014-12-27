package Example::Construction::Acme::Counter_v2;

use Minions::Implementation
    has  => {
        count => { },
    }, 
;

sub BUILD {
    my (undef, $self, $arg) = @_;

    $self->{$__count} = $arg->{start};
}

sub next {
    my ($self) = @_;

    $self->{$__count}++;
}

1;
