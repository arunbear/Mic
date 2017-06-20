package Example::Construction::Acme::CounterWithNew;

use Moduloop::Imp
    has  => {
        count => { init_arg => 'start' },
    }, 
    classmethod => ['new'],
;

sub next {
    my ($self) = @_;

    $self->{$COUNT}++;
}

sub new {
    my ($class, $start) = @_;

    my $builder = Moduloop::builder_class($class);
    my $obj = $builder->new_object({count => $start});
    return $obj;
};

1;
