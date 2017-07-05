package Example::Construction::Acme::CounterWithNew;

use Moduloop::Impl
    has  => {
        COUNT => { init_arg => 'start' },
    }, 
    classmethod => ['new'],
;

sub next {
    my ($self) = @_;

    $self->[ $COUNT ]++;
}

sub new {
    my ($class, $start) = @_;

    my $builder = Moduloop::builder_for($class);
    my $obj = $builder->new_object({COUNT => $start});
    return $obj;
};

1;
