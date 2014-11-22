package Example::Construction::Counter_v3;

use strict;
use Class::Minion
    interface => [ qw( next ) ],

    construct_with => {
        start => {
            assert => {
                is_integer => sub { $_[0] =~ /^\d+$/ }
            },
        },
    },
    class_methods => {
        new => sub {
            my ($class, $start) = @_;

            $class->__assert__('start' => $start);
            my $obj = $class->__new__;
            $obj->{$$}{count} = $start;
            return $obj;
        },
    },

    implementation => 'Example::Construction::Acme::Counter';

1;
