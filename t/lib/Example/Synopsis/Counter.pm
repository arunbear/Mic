package Example::Synopsis::Counter;

use Minion
    interface => [ qw( next ) ],
    implementation => 'Example::Synopsis::Acme::Counter';

1;
