package Example::Delegates::MultiQueue;

use Moduloop
    interface => [qw( multi_push multi_pop )],

    implementation => 'Example::Delegates::Acme::MultiQueue',
;

1;
