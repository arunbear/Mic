package Moduloop::Imp;

require Moduloop::Implementation;

our @ISA = qw( Moduloop::Implementation );

1;

__END__

=head1 NAME

Moduloop::Imp

=head1 SYNOPSIS

    package Example::Construction::Acme::Set_v1;

    use Moduloop::Imp
        has => {
            set => {
                default => sub { {} },
                init_arg => 'items',
                map_init_arg => sub { return { map { $_ => 1 } @{ $_[0] } } },
            }
        },
    ;

    sub has {
        my ($self, $e) = @_;
        exists $self->{$SET}{$e};
    }

    sub add {
        my ($self, $e) = @_;
        ++$self->{$SET}{$e};
    }

    1;

=head1 DESCRIPTION

Moduloop::Imp is an alias of L<Moduloop::Implementation>, provided for convenience.
