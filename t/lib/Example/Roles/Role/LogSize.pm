package Example::Roles::Role::LogSize;

use Moduloop::Role
    requires => [qw/ pop size /],

    around => {
        pop => sub {
            my $orig = shift;
            my $self = shift;
            warn sprintf "[%s] I have %d element(s)\n", scalar(localtime), $self->size;
            $orig->($self, @_);
        },
    },
;

1;
