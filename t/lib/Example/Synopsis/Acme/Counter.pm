package Example::Synopsis::Acme::Counter;

use Moduloop::Implementation
    has => {
        COUNT => { default => 0 },
    } 
;

sub next {
    my ($self) = @_;

    $self->{$COUNT}++;
}

1;
