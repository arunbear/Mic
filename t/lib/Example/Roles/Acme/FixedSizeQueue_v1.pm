package Example::Roles::Acme::FixedSizeQueue_v1;

use Minions::Implementation
    has  => {
        q => { default => sub { [ ] } },

        max_size => { 
            init_arg => 'max_size',
        },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$__q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$__q} }, $val;

    if ($self->size > $self->{$__max_size}) {
        $self->pop;        
    }
}

sub pop {
    my ($self) = @_;
    shift @{ $self->{$__q} };
}

1;
