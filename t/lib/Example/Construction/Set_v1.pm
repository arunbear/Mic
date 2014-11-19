
package Example::Construction::Set_v1;

use strict;
use Class::Minion ();

our %__Meta = (
    interface => [qw( add has )],

    implementation => 'Example::Construction::Acme::Set_v1',
);
Class::Minion->minionize;
