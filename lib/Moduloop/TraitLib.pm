package Moduloop::TraitLib;

use Scalar::Util qw( reftype );
require Moduloop::Implementation;

our @ISA = qw( Moduloop::Implementation );

sub update_args {
    my ($class, $arg) = @_;

    $arg->{traitlib} = 1;
}

sub install_subs {
    my ($class, $stash) = @_;

    my $meta = \ %Moduloop::_Guts::Implementation_meta;

    $stash->add_symbol('&GET_ATTR',
        sub {
            my ($obj, $attr) = @_;

            if ( reftype $obj eq 'ARRAY' ) {
                $attr =~ s/.*-//;
                my $offset = $meta->{ref $obj}{slot_offset}{$attr};
                return $obj->[$offset];
            }
            else {
                return $obj->{$attr};
            }
        }
    );
    $stash->add_symbol('&SET_ATTR',
        sub {
            my ($obj, $attr, $val) = @_;

            if ( reftype $obj eq 'ARRAY' ) {
                $attr =~ s/.*-//;
                my $offset = $meta->{ref $obj}{slot_offset}{$attr};
                $obj->[$offset] = $val;
            }
            else {
                $obj->{$attr} = $val;
            }
        }
    );
}
1;

__END__

=head1 NAME

Moduloop::TraitLib

=head1 SYNOPSIS

    package Foo::TraitLib;

    use Moduloop::TraitLib
        has  => {
            beans => { default => sub { [ ] } },
        }, 
        requires => {
            methods    => [qw/some required methods/],
            attributes => [qw/some required attributes/],
        },
        traits => { 
            traitlib1 => {
                methods    => [qw/some methods/],
                attributes => [qw/some attributes/],
            },
            ...
        },
        semiprivate => [qw/some internal subs/],
    ;

=head1 DESCRIPTION

TraitLibs provide reusable implementation details, i.e. they solve the problem of what to do when the same implementation details are found in more than one implementation package.

=head1 CONFIGURATION

A traitlib package can be configured either using Moduloop::TraitLib or with a package variable C<%__meta__>. Both methods make use of the following keys:

=head2 has => HASHREF

This works the same way as in an implementation package.

=head2 requires => HASHREF

A hash with keys:

=head3 methods => ARRAYREF

Any methods listed here must be provided by an implementation package or a traitlib.

=head3 attributes => ARRAYREF

Any attributes listed here must be provided by an implementation package or a traitlib.

Variables with names corresponding to these attributes will be created in the traitlib package to allow accessing the attributes e.g.

    use Moduloop::TraitLib
        requires => {
            attributes => [qw/length width/]

        };

    sub area {
        my ($self) = @_;
        $self->{$LENGTH} * $self->{$WIDTH};
    }

=head2 traits => HASHREF

A hash of traitlibs which the current traitlib is composed out of (traitlibs can be built from other traitlibs). The structure of this list is just like the C<traits> specification in L<Moduloop::Implementation>

=head2 semiprivate => ARRAYREF

A list of semiprivate methods. These are methods provided by the traitlib that are not indended
to be used by end users of the class that the traitlib was used in.

Each implementation package has a corresponding semiprivate package where its semiprivate methods live. This package can be accessed from an object via the variable C<$__> which is created by Moduloop::TraitLib (and also by Moduloop::Implementation).

A semiprivate method can then be called like this

    $self->{$__}->some_work($self, ...);

Since a semiprivate method is receives a package name as its first argument, the C<$self> variable must be explicitly passed to it, if it needs access to the object that called it.

As this syntax is somewhat cumbersome, it is also possible to call a semiprivate method via the usual method call syntax i.e.
 
    $self->some_work(...);

but this is only valid if called within the object's implementation package, or a traitlib that the implementation is composed out of.

=head2 traitlib => 1

Only needed if Moduloop::TraitLib is not used. This indicates that the package is a TraitLib.

=head1 EXAMPLES

=head2 Queueing and Stacking

First consider a queue which we would use like this:

    use Test::More;
    use Example::TraitLibs::Queue_v1;

    my $q = Example::TraitLibs::Queue_v1->new;

    is $q->size => 0;

    $q->push(1);
    is $q->size => 1;

    $q->push(2);
    is $q->size => 2;

    my $n = $q->pop;
    is $n => 1;
    is $q->size => 1;
    done_testing();

The Queue class:

    package Example::TraitLibs::Queue_v1;

    use Moduloop
        interface => [qw( push pop size )],

        implementation => 'Example::TraitLibs::Acme::Queue_v1',
    ;

    1;

And its implementation:

    package Example::TraitLibs::Acme::Queue_v1;

    use Moduloop::Implementation
        has  => {
            items => { default => sub { [ ] } },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$ITEMS} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$ITEMS} }, $val;
    }

    sub pop {
        my ($self) = @_;

        shift @{ $self->{$ITEMS} };
    }

    1;

Now consider a stack with this usage:

    use Test::More;
    use Example::TraitLibs::Stack;

    my $s = Example::TraitLibs::Stack->new;

    is $s->size => 0;

    $s->push(1);
    is $s->size => 1;

    $s->push(2);
    is $s->size => 2;

    my $n = $s->pop;
    is $n => 2;
    is $s->size => 1;
    done_testing();

Its class and implementation:

    package Example::TraitLibs::Stack;

    use Moduloop
        interface => [qw( push pop size )],

        implementation => 'Example::TraitLibs::Acme::Stack_v1',
    ;

    1;

    package Example::TraitLibs::Acme::Stack_v1;

    use Moduloop::Implementation
        has  => {
            items => { default => sub { [ ] } },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$ITEMS} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$ITEMS} }, $val;
    }

    sub pop {
        my ($self) = @_;

        pop @{ $self->{$ITEMS} };
    }

    1;

The two implementations are very similar, both containing an "items" attribute, the "size" and "push" methods. The "pop" methods are almost the same, the only difference being whether an item is removed from the front or the back of the array.

Suppose we wanted to factor out the commonality of the two implementations. We can use a traitlib to do this:

    package Example::TraitLibs::TraitLib::Pushable;

    use Moduloop::TraitLib
        has  => {
            items => { default => sub { [ ] } },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$ITEMS} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$ITEMS} }, $val;
    }

    1;

The traitlib provides the "items" attribute, the "size" and "push" methods.

Now using this traitlib, the Queue implementation can be simplified to this:

    package Example::TraitLibs::Acme::Queue_v2;

    use Moduloop::Implementation
        traits => {
            Example::TraitLibs::TraitLib::Pushable => {
                methods    => [qw( push size )],
                attributes => [qw/items/]
            }
        },
    ;

    sub pop {
        my ($self) = @_;

        shift @{ $self->{$ITEMS} };
    }

    1;

And the Stack implementation can be simplified to this:

    package Example::TraitLibs::Acme::Stack_v2;

    use Moduloop::Implementation
        traits => {
            Example::TraitLibs::TraitLib::Pushable => {
                methods    => [qw( push size )],
                attributes => [qw/items/]
            }
        },
    ;

    sub pop {
        my ($self) = @_;

        pop @{ $self->{$ITEMS} };
    }

    1;

To test these new implementations, we don't even need to update the main classes because we can re-bind them to new implementations quite easily:

    use Test::More;

    use Moduloop
        bind => {
            'Example::TraitLibs::Queue' => 'Example::TraitLibs::Acme::Queue_v2',
        };
    use Example::TraitLibs::Queue;

    my $q = Example::TraitLibs::Queue->new;

    is $q->size => 0;

    $q->push(1);
    is $q->size => 1;

    $q->push(2);
    is $q->size => 2;

    my $n = $q->pop;
    is $n => 1;
    is $q->size => 1;
    done_testing();

=head2 Using multiple traitlibs

An implementation can get its functionality from more than one traitlib. As an example consider adding logging of the size as was done in L<Moduloop::Implementation/PRIVATE ROUTINES>.

Such functionality does not logically belong in the Pushable traitlib, but we could create a new traitlib for it

    package Example::TraitLibs::TraitLib::LogSize;

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

Now we can use this traitlib too

    package Example::TraitLibs::Acme::Queue_v3;

    use Moduloop::Implementation
        traits => {
            Example::TraitLibs::TraitLib::Pushable => {
                methods    => [qw( push size )],
                attributes => [qw/items/]
            },
            Example::TraitLibs::TraitLib::LogSize => {
                methods    => [qw( log_info )],
            }
        },
    ;

    sub pop {
        my ($self) = @_;

        $self->{$__}->log_info($self);
        # or just
        # $self->log_info;

        shift @{ $self->{$ITEMS} };
    }

    1;

And use the queue like this

    % reply -I t/lib
    0> use Moduloop bind => { 'Example::TraitLibs::Queue' => 'Example::TraitLibs::Acme::Queue_v3' }
    1> use Example::TraitLibs::Queue
    2> my $q = Example::TraitLibs::Queue->new
    $res[0] = bless( {
        '83cb834b-' => 'Example::TraitLibs::Queue::__Private',
        '83cb834b-items' => []
    }, 'Example::TraitLibs::Queue::__Moduloop' )

    3> $q->push(1)
    $res[1] = 1

    4> $q->pop
    [Tue Mar  3 18:24:08 2015] I have 1 element(s)
    $res[2] = 1

    5> $q->can
    $res[3] = [
    'pop',
    'push',
    'size'
    ]

    6> $q->DOES
    $res[4] = [
        'Example::TraitLibs::Queue',
        'Example::TraitLibs::TraitLib::LogSize',
        'Example::TraitLibs::TraitLib::Pushable'
    ]

    7>

The last two commands show L<Moduloop>' support for introspection.
