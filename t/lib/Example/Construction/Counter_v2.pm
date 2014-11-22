package Example::Construction::Counter_v2;

use strict;
use Class::Minion ();

our %__Meta = (
    interface => [ qw( next ) ],

    construct_with => {
        start => {
            assert => {
                is_integer => sub { $_[0] =~ /^\d+$/ }
            },
        },
    },
    implementation => 'Example::Construction::Acme::Counter',
);

sub new {
    my ($class, $start) = @_;

    $class->__assert__('start' => $start);
    my $obj = $class->__new__;
    $obj->{$$}{count} = $start;
    return $obj;
}

Class::Minion->minionize;
