package Example::Roles::Acme::Queue_v2;

use Moduloop::Implementation
    roles => ['Example::Roles::Role::Pushable'],

    requires => {
        attributes => [qw/items/]
    };
;

sub pop {
    my ($self) = @_;

    shift @{ $self->{$ITEMS} };
}

1;
