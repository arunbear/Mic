package Example::Roles::Acme::Queue_v3;

use Moduloop::Implementation
    traits => {
        Example::Roles::Role::Pushable => {
            methods    => [qw( push size )],
            attributes => ['items']
        },
        Example::Roles::Role::LogSize => {
            methods    => [qw( log_info )],
        }
    },
;

sub pop {
    my ($self) = @_;

    $self->log_info;
    shift @{ $self->{$ITEMS} };
}

1;
