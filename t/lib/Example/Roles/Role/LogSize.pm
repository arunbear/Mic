package Example::Roles::Role::LogSize;

use Moduloop::Role
    requires => [qw/ size /],
    semiprivate => ['log_info'],
;

sub log_info {
    my (undef, $self) = @_;

    warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
}

1;
