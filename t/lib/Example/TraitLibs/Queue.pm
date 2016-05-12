package Example::TraitLibs::Queue;

use Moduloop
    interface => [qw( push pop size )],

    implementation => 'Example::TraitLibs::Acme::Queue_v1',
;

1;
