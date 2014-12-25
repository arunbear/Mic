package Example::Construction::Acme::Counter;

use Minions::Implementation
    has  => {
        count => { init_arg => 'start' },
    }, 
;

sub next {
    my ($self) = @_;

    $self->{$__Count}++;
}

1;
