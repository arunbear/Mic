package Example::Construction::Set_v1;

use Class::Minion

    interface => [qw( add has )],
    construct_with => { items => {} },

    build_args => sub {
        my ($class, @items) = @_;

        return { items => \@items };
    },

    implementation => 'Example::Construction::Acme::Set_v1',
;

1;
