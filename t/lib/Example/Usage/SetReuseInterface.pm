package Example::Usage::SetReuseInterface;

use Minion
    interface => 'Example::Usage::SetInterface',

    implementation => 'Example::Usage::ArraySet',
    ;
1;
