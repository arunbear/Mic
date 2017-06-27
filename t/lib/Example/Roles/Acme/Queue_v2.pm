package Example::Roles::Acme::Queue_v2;

use Moduloop::Implementation
    roles => ['Example::Roles::Role::Pushable'],

    around => {
        pop => sub {
            my ($orig, $self) = @_;

            $orig->($self, 0);
        },
    },
;

1;
