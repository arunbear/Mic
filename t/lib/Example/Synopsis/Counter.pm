package Example::Synopsis::Counter;

use Moduloop
    interface => [ qw( next ) ],
    implementation => 'Example::Synopsis::Acme::Counter';

1;
