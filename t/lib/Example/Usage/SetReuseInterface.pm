package Example::Usage::SetReuseInterface;

use Class::Minion
    interface => 'Example::Usage::SetInterface',

    implementation => 'Example::Usage::ArraySet',
    ;
1;
