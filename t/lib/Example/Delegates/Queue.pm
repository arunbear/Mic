package Example::Delegates::Queue;

use Moduloop
    interface => [qw( push pop size )],

    implementation => 'Example::Delegates::Acme::Queue_v1',
;

1;
