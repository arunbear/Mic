package Example::Synopsis::Counter;

use strict;
use Minion;

our %__Meta = (
    interface => [qw(next)],
    implementation => 'Example::Synopsis::Acme::Counter',
);
Minion->minionize;