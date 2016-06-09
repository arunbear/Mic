package Example::Construction::Counter_v2;

use strict;
use Moduloop ();

our %__meta__ = (
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
    implementation => 'Example::Construction::Acme::Counter',
);

sub new {
    my ($class, $start) = @_;

    my $builder = Moduloop::builder_class($class);
    $builder->assert(start => $start);
    my $obj = $builder->new_object({count => $start});
    return $obj;
}

Moduloop->assemble;
