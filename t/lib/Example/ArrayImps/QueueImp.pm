package Example::ArrayImps::QueueImp;

use Moduloop::ArrayImp
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
