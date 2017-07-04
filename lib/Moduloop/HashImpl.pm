package Moduloop::HashImpl;

require Moduloop::Implementation;

our @ISA = qw( Moduloop::Implementation );

1;

__END__

=head1 NAME

Moduloop::HashImpl

=head1 SYNOPSIS

    package Example::Construction::Acme::Set_v1;

    use Moduloop::HashImpl
        has => {
            SET => {
                default => sub { {} },
                init_arg => 'items',
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

Moduloop::HashImpl is an alias of L<Moduloop::Implementation>, provided for convenience.
