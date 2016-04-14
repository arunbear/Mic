package Example::Roles::Acme::Stack_v2;

use Moduloop::Implementation
    roles => ['Example::Roles::Role::Pushable'],

    requires => {
        attributes => [qw/items/]
    };
;

sub pop {
    my ($self) = @_;

    pop @{ $self->{$__items} };
}

1;
