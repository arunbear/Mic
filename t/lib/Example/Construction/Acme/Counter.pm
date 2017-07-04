package Example::Construction::Acme::Counter;

use Moduloop::Imp
    has  => {
        COUNT => { init_arg => 'start' },
    }, 
;

sub next {
    my ($self) = @_;

    $self->{$COUNT}++;
}

1;
