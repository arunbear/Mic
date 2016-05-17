package Example::TraitLibs::TraitLib::Pushable;

use Moduloop::TraitLib
    has  => {
        items => { default => sub { [ ] } },
    }, 
;

sub size {
    my ($self) = @_;
    scalar @{ GET_ATTR($self, $ITEMS) };
}

sub push {
    my ($self, $val) = @_;

    push @{ GET_ATTR($self, $ITEMS) }, $val;
}

1;
