package Example::Roles::Role::LogSize;

use Moduloop::TraitLib
    semiprivate => ['log_info'],
    requires => {
        methods => [qw/ size /],
    },
;

sub log_info {
    my (undef, $self) = @_;

    warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
}

1;
