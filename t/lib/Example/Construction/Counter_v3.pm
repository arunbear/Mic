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

            my $utility_class = Class::Minion::utility_class($class);
            $utility_class->assert('start' => $start);
            my $obj = $utility_class->new_object;
            $obj->{$$}{count} = $start;
            return $obj;
        },
    },

    implementation => 'Example::Construction::Acme::Counter';

1;
