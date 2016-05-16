package Example::ArrayImps::HashSet;

use Moduloop::ArrayImp
    has => { set => { default => sub { {} } } },
;

sub has {
    my ($self, $e) = @_;
    exists $self->[ $SET ]{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->[ $SET ]{$e};
}

1;
