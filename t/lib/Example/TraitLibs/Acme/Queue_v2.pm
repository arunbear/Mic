package Example::TraitLibs::Acme::Queue_v2;

use Moduloop::Implementation
    traits => {
        Example::TraitLibs::TraitLib::Pushable => {
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
