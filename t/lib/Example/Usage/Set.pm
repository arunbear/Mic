package Example::Usage::Set;

use Minion
    interface => [qw( add has )],

    implementation => 'Example::Usage::ArraySet',
    ;
1;
