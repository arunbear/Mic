package Example::Roles::Acme::Queue_v2;

use Moduloop::Implementation
    traits => {
        Example::Roles::Role::Pushable => {
            methods    => [qw( push size )],
            attributes => ['items']
        }
    },
;

sub pop {
    my ($self) = @_;

    shift @{ $self->{$ITEMS} };
}

1;
