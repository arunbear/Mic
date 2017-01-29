# The evolution of a simple Set class

package Example::Synopsis::Set;

use Moduloop
    interface => {
        object => {
            add => {},
            has => {},
        },
        class => {
            new => {},
        }
    },

    implementation => 'Example::Synopsis::ArraySet',
    ;
1;
