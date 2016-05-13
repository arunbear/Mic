package Example::TraitLibs::Acme::Stack_v2;

use Moduloop::Implementation
    traits => {
        Example::TraitLibs::TraitLib::Pushable => {
            methods    => [qw( push size )],

            attributes => [qw/items/]
        }
    },
;

sub pop {
    my ($self) = @_;

    pop @{ $self->{$ITEMS} };

}

1;
