package Example::Construction::Counter_v3;

use strict;
use Moduloop
    interface => [ qw( next ) ],

    constructor => { 
        kv_args => {
            start => {
                callbacks => {
                    is_integer => sub { $_[0] =~ /^\d+$/ }
                },
            },
        }
    },
    class_methods => {
        new => sub {
            my ($class, $start) = @_;

            my $builder = Moduloop::builder_class($class);
            $builder->assert(start => $start);
            my $obj = $builder->new_object({count => $start});
            return $obj;
        },
    },

    implementation => 'Example::Construction::Acme::Counter';

1;
