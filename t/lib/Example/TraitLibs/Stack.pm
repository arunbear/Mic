package Example::TraitLibs::Stack;

use Moduloop
    interface => [qw( push pop size )],

    implementation => 'Example::TraitLibs::Acme::Stack_v1',
;

1;

