package Example::Delegates::Queue;

use Moduloop
    interface => [qw( push pop head tail size )],

    implementation => 'Example::Delegates::Acme::Queue_v1',
;

1;
