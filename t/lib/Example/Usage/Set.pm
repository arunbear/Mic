package Example::Usage::Set;

use Moduloop ();

Moduloop->assemble({
    interface => { 
        object => {
            add => {},
            has => {},
        },
        class => { new => {} }
    },

    implementation => 'Example::Usage::HashSet',
});

package Example::Usage::HashSet;

use Moduloop::Implementation
    has => { set => { default => sub { {} } } },
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
