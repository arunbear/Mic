package Example::Roles::Acme::Queue_v1;

use Minions::Implementation
    has  => {
        q => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$__q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$__q} }, $val;
}

sub pop {
    my ($self) = @_;
    shift @{ $self->{$__q} };
}

1;
