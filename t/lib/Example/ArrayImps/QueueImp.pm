package Example::ArrayImps::QueueImp;

use Moduloop::ArrayImpl
    traits => {
        Example::TraitLibs::TraitLib::Pushable => {
            methods    => [qw( push size )],
            attributes => ['ITEMS']
        }
    },
;

sub pop {
    my ($self) = @_;

    shift @{ $self->[$ITEMS] };
}

1;
