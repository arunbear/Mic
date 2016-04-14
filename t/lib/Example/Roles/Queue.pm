package Example::Roles::Queue;

use Moduloop
    interface => [qw( push pop size )],

    implementation => 'Example::Roles::Acme::Queue_v1',
;

1;
