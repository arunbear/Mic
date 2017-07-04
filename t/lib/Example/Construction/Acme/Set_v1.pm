package Example::Construction::Acme::Set_v1;

use Moduloop::Implementation
    has => { 
        SET => {
            default => sub { {} },
            init_arg => 'items',
        } 
    },
;

sub has {
    my ($self, $e) = @_;

    log_info($self);
    exists $self->{$SET}{$e};
}

sub add {
    my ($self, $e) = @_;

    log_info($self);
    ++$self->{$SET}{$e};
}

sub log_info {
    my ($self) = @_;

    warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
}

sub size {
    my ($self) = @_;
    scalar(keys %{ $self->{$SET} });
}

1;
