package Example::Roles::Acme::Stack_v2;

use Moduloop::Implementation
    roles => ['Example::Roles::Role::Pushable'],
;

sub pop {
    my ($self) = @_;

    $self->remove(-1);
}

1;
