package Example::Synopsis::Set;

use Moduloop
    interface => [qw( add has )],

    implementation => 'Example::Synopsis::ArraySet',
    ;
1;
