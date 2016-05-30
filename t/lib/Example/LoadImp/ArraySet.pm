package Example::LoadImp::ArraySet;

use Moduloop::Implementation
    interface => 'Example::LoadImp::Set',

    has => { set => { default => sub { [] } } },
;

sub has {
    my ($self, $e) = @_;
    scalar grep { $_ == $e } @{ $self->{$SET} };
}

sub add {
    my ($self, $e) = @_;

    if ( ! $self->has($e) ) {
        push @{ $self->{$SET} }, $e;
    }
}

1;
