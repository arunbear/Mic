package Example::Synopsis::Counter;

use Class::Minion
    interface => [ qw( next ) ],
    implementation => 'Example::Synopsis::Acme::Counter';

1;
