package Example::Usage::Set;

use Class::Minion
    interface => [qw( add has )],

    implementation => 'Example::Usage::ArraySet',
    ;
1;
