package Example::Roles::Stack;

use Moduloop
    interface => [qw( push pop size )],

    implementation => 'Example::Roles::Acme::Stack_v1',
;

1;

