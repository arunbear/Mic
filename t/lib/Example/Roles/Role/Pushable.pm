package Example::Roles::Role::Pushable;

use Moduloop::Role
    has  => {
        items => { default => sub { [ ] } },
    }, 
    semiprivate => ['remove'],
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$ITEMS} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$ITEMS} }, $val;
}

sub remove {
    my (undef, $self, $i) = @_;

    splice @{ $self->{$ITEMS} }, $i, 1;
}

1;
