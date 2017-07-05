package Moduloop::Impl;

require Moduloop::ArrayImpl;

our @ISA = qw( Moduloop::ArrayImpl );

1;

__END__

=head1 NAME

Moduloop::Impl

=head1 SYNOPSIS

    package Example::Construction::Acme::Counter;

    use Moduloop::Impl
        has  => {
            COUNT => { init_arg => 'start' },
        }, 
    ;

    sub next {
        my ($self) = @_;

        $self->[ $COUNT ]++;
    }

    1;

=head1 DESCRIPTION

Moduloop::Impl is an alias of L<Moduloop::ArrayImpl>, provided for convenience.
