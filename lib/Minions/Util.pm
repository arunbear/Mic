package Minions::Util;

use Exporter qw( import );

our @EXPORT_OK = qw( call_semiprivate call_sp );

sub call_semiprivate {
    my ($obj, $name, @args) = @_;

    my $pkg = (caller)[0];
    no strict 'refs';
    my $sp_var = ${"${pkg}::__"};
    $obj->{$sp_var}->$name($obj, @args);
}

*call_sp = \&call_semiprivate;

1;

__END__

=head1 NAME

Minions::Util

=head1 SYNOPSIS

    package Example::Roles::Acme::Queue_v3;

    use Minions::Implementation
        roles => [qw/
            Example::Roles::Role::Pushable
            Example::Roles::Role::LogSize
        /],

        requires => {
            attributes => [qw/items/]
        };
    ;
    use Minions::Util 'call_sp';

    sub pop {
        my ($self) = @_;

        call_sp($self => 'log_info');
        shift @{ $self->{$__items} };
    }

    1;

=head1 DESCRIPTION

Utility functions for use with Minions, exported on demand.

=head1 FUNCTIONS 

=head2 call_semiprivate(OBJ, SUB_NAME, ...)

Provides a shorcut for calling semiprivate routines, so that

    $self->{$__}->internal_func($self, @args);

can also be accomplished by

    call_semiprivate($self, 'internal_func', @args);

Note that this function is only intended for use in an implementation or role.

=head2 call_sp(OBJ, SUB_NAME, ...)

C<call_sp> is an alias for C<call_semiprivate>
