package Example::ArrayImps::HashSet;

use Moduloop::ArrayImp
    has => { set => { default => sub { {} } } },
    semiprivate => ['log_info'],
;

sub has {
    my ($self, $e) = @_;
    exists $self->[ $SET ]{$e};
}

sub add {
    my ($self, $e) = @_;
    ++$self->[ $SET ]{$e};
    $self->log_info;
}

sub log_info {
    my (undef, $self) = @_;

    warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), scalar(keys %{ $self->[$SET] });
}

1;
