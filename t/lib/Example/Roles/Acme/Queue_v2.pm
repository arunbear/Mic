package Example::Roles::Acme::Queue_v2;

use Moduloop::Implementation
    roles => ['Example::Roles::Role::Pushable'],
;

sub pop {
    my ($self) = @_;

    $self->remove(0);
}

1;
