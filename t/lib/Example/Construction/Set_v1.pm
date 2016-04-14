package Example::Construction::Set_v1;

use Moduloop

    interface => [qw( add has size )],
    construct_with => { items => {} },

    build_args => sub {
        my ($class, @items) = @_;

        return { items => \@items };
    },

    implementation => 'Example::Construction::Acme::Set_v1',
;

1;
