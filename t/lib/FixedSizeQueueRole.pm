package FixedSizeQueueRole;

use Minions::Role
    has  => {
        q => { default => sub { [ ] } },
        max_size => { 
            init_arg => 'max_size',
            reader => 1,
        },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$__Q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$__Q} }, $val;
}

1;
