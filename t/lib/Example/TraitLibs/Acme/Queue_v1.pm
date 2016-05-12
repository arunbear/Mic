package Example::TraitLibs::Acme::Queue_v1;

use Moduloop::Implementation
    has  => {
        items => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$ITEMS} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$ITEMS} }, $val;
}

sub pop {
    my ($self) = @_;

    shift @{ $self->{$ITEMS} };
}

1;
