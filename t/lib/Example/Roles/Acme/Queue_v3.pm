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
