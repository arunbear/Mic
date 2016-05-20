package Example::TraitLibs::Acme::FixedSizeQueue_v3;

use Moduloop::Implementation
    traits => {
        Example::TraitLibs::TraitLib::FixedSizeQueue => {
            methods    => [qw( push pop size )],
            attributes => [qw( Q MAX_SIZE )]
        }
    },
;

1;
