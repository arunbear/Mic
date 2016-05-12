package Example::TraitLibs::Acme::Queue_v3;

use Moduloop::Implementation
    traits => {
        Example::TraitLibs::TraitLib::Pushable => {
            methods    => [qw( push size )],
            attributes => ['items']
        },
        Example::TraitLibs::TraitLib::LogSize => {
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
