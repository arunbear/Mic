package Example::Construction::Set_v1;

sub BUILDARGS {
    my ($class, @items) = @_;

    return { items => { map { $_ => 1 } @items } };
}

use Class::Minion

    interface => [qw( add has )],
    construct_with => { items => {} },

    implementation => 'Example::Construction::Acme::Set_v1',
;

1;
