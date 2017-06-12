package Example::Construction::Set_v2;

use Moduloop

    interface => [qw( add has size )],

    implementation => 'Example::Construction::Acme::Set_v2',
;

1;
