package Example::Roles::Acme::Queue_v3;

use Moduloop::Implementation
    roles => [qw/
        Example::Roles::Role::Pushable
        Example::Roles::Role::LogSize
    /],
;

sub pop {
    my ($self) = @_;

    $self->log_info;
    $self->remove(0);
}

1;
