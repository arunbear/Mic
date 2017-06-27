package Example::Roles::Role::Pushable;

use Moduloop::Role
    has  => {
        items => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$ITEMS} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$ITEMS} }, $val;
}

sub pop {
    my ($self, $i) = @_;

    splice @{ $self->{$ITEMS} }, $i, 1;
}

1;
