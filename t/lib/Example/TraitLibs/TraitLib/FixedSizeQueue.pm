package Example::TraitLibs::TraitLib::FixedSizeQueue;

use Example::Delegates::Queue;

use Moduloop::TraitLib
    has  => {
        Q => { 
            default => sub { Example::Delegates::Queue->new },
        },

        MAX_SIZE => { 
            init_arg => 'max_size',
        },
    }, 
    forwards => [
        {
            send => [qw( size pop )],
            to   => 'Q'
        },
    ],
;

sub push {
    my ($self, $val) = @_;

    GET_ATTR($self, 'Q')->push($val);

    if ($self->size > GET_ATTR($self, 'MAX_SIZE')) {
        $self->pop;        
    }
}

1;
