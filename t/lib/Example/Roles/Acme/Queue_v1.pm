package Example::Roles::Acme::Queue_v1;

use Minions::Implementation
    has  => {
        items => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$__items} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$__items} }, $val;
}

sub pop {
    my ($self) = @_;

    shift @{ $self->{$__items} };
}

1;
