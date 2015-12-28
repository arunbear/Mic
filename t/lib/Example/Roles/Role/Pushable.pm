package Example::Roles::Role::Pushable;

use Minions::Role
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

1;
