package Example::TraitLibs::Acme::FixedSizeQueue_v3;

use Moduloop::Implementation
    has  => {
        max_size => { 
            init_arg => 'max_size',
        },
    }, 
    semiprivate => ['after_push'],
    roles => [qw/
        Example::TraitLibs::TraitLib::Queue
        Example::TraitLibs::TraitLib::LogSize
    /]
;

sub after_push {
    my (undef, $self) = @_;

    if ($self->size > $self->{$__max_size}) {
        $self->pop;        
    }
    $self->{$__}->log_info($self);
}

1;
