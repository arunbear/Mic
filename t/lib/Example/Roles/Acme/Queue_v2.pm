package Example::Roles::Acme::Queue_v2;

use Minions::Implementation
    roles => ['Example::Roles::Role::Pushable'],

    requires => {
        attributes => [qw/items/]
    };
;

sub pop {
    my ($self) = @_;

    shift @{ $self->{$__items} };
}

1;
