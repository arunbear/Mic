package Example::Roles::Acme::Stack_v1;

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

    pop @{ $self->{$__items} };
}

1;
