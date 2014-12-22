package Minions::Role;

require Minions::Implementation;

our @ISA = qw( Minions::Implementation );

sub update_args {
    my ($class, $arg) = @_;

    $arg->{role} = 1;    
}

1;
