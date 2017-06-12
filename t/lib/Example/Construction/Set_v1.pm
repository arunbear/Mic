package Example::Construction::Set_v1;

use Moduloop

    interface => [qw( add has size )],

    implementation => 'Example::Construction::Acme::Set_v1',
;

1;
