package Moduloop::ArrayImp;

use Readonly;
require Moduloop::Implementation;

our @ISA = qw( Moduloop::Implementation );

sub update_args {
    my ($class, $arg) = @_;

    $arg->{arrayimp} = 1;
}

sub add_attribute_syms {
    my ($class, $arg, $stash) = @_;

    my @slots = (
        '__', # semiprivate pkg
        keys %{ $arg->{has} },
    );
    foreach my $i ( 0 .. $#slots ) {
        $class->add_sym($stash, $slots[$i], $i);
    }
}

sub add_sym {
    my ($class, $stash, $slot, $i) = @_;

    Readonly my $sym_val => $i;
    $Moduloop::_Guts::slot_offset{$slot} = $sym_val;

    $stash->add_symbol(
        sprintf('$%s', uc $slot),
        \ $sym_val
    );
}

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
