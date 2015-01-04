package Example::Roles::Role::Queue;

use Minions::Role
    has  => {
        q => { default => sub { [ ] } },
    }, 
    semiprivate => ['after_push'],
;

sub size {
    my ($self) = @_;
    scalar @{ $self->{$__q} };
}

sub push {
    my ($self, $val) = @_;

    push @{ $self->{$__q} }, $val;

    $self->{$__}->after_push($self);
}

sub pop {
    my ($self) = @_;
    shift @{ $self->{$__q} };
}

sub after_push { }

1;
