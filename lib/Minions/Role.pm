package Minions::Role;

require Minions::Implementation;

our @ISA = qw( Minions::Implementation );

sub update_args {
    my ($class, $arg) = @_;

    $arg->{role} = 1;    
}

1;

__END__

=head1 NAME

Minions::Role

=head1 SYNOPSIS

    package Foo::Role;

    use Minions::Role
        has  => {
            beans => { default => sub { [ ] } },
        }, 
        requires => {
            methods => [qw/some required methods/],
            attributes => [qw/some required attributes/],
        },
        roles => [qw/all these roles/],
        semiprivate => [qw/some internal subs/],
    ;

=head1 DESCRIPTION

Roles provide reusable implementation details, i.e. they solve the problem of what to do when the same implementation details are found in more than one implementation package.

=head1 CONFIGURATION

A role package can be configured either using Minions::Role or with a package variable C<%__meta__>. Both methods make use of the following keys:

=head2 has => HASHREF

This works the same way as in an implementation package.

=head2 requires => HASHREF

A hash with keys:

=head3 methods => ARRAYREF

Any methods listed here must be provided by an implementation package or a role.

=head3 attributes => ARRAYREF

Any attributes listed here must be provided by an implementation package or a role.

Variables with names corresponding to these attributes will be created in the role package to allow accessing the attributes e.g.

    use Minions::Role
        requires => {
            attributes => [qw/length width/]

        };

    sub area {
        my ($self) = @_;
        $self->{$__length} * $self->{$__width};
    }

=head2 roles => ARRAYREF

A list of roles which the current role is composed out of (roles can be built from other roles).

=head2 semiprivate => ARRAYREF

A list of semiprivate methods. These are methods provided by the role that are not indended
to be used by end users of the class that the role was used in.

Such methods can't be called with the C<$minion-E<gt>do_something()> syntax. Instead they are called this way

    $self->{$__}->some_work($self, ...);

Each implementation package has a corresponding semiprivate package where its semiprivate methods live. This package can be accessed from an object via the variable C<$__> which is created by Minions::Role (and also by Minions::Implementation).

Since a semiprivate method is called with a package name as its first argument, the C<$self> variable must be explicitly passed to it, if it needs access to the object that called it.
 
=head2 role => 1

Only needed if Minions::Role is not used. This indicates that the package is a Role.

=head1 EXAMPLES

=head2 Queueing Up

First consider a queue which we would use like this:

    use strict;
    use Test::More;
    use Example::Roles::Queue_v1;

    my $q = Example::Roles::Queue_v1->new;

    is $q->size => 0;

    $q->push(1);
    is $q->size => 1;

    $q->push(2);
    is $q->size => 2;

    $q->pop;
    is $q->size => 1;
    done_testing();

The Queue class:

    package Example::Roles::Queue_v1;

    use Minions
        interface => [qw( push pop size )],

        implementation => 'Example::Roles::Acme::Queue_v1',
    ;

    1;

And its implementation:

    package Example::Roles::Acme::Queue_v1;

    use Minions::Implementation
        has  => {
            q => { default => sub { [ ] } },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$__q} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$__q} }, $val;
    }

    sub pop {
        my ($self) = @_;
        shift @{ $self->{$__q} };
    }

    1;

Now consider a queue which maintains a fixed size by evicting the oldest items:

    use strict;
    use Test::More;
    use FixedSizeQueue_v1;

    my $q = FixedSizeQueue_v1->new(max_size => 3);

    $q->push($_) for 1 .. 3;
    is $q->size => 3;

    $q->push($_) for 4 .. 6;
    is $q->size => 3;
    is $q->pop => 4;
    done_testing();

Its class and implementation:

    package Example::Roles::FixedSizeQueue_v1;

    use Minions
        interface => [qw( push pop size )],

        construct_with  => {
            max_size => { 
                assert => { positive_int => sub { $_[0] =~ /^\d+$/ && $_[0] > 0 } }, 
            },
        }, 

        implementation => 'Example::Roles::Acme::FixedSizeQueue_v1',
    ;

    1;

    package Example::Roles::Acme::FixedSizeQueue_v1;

    use Minions::Implementation
        has  => {
            q => { default => sub { [ ] } },

            max_size => { 
                init_arg => 'max_size',
            },
        }, 
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$__q} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$__q} }, $val;

        if ($self->size > $self->{$__max_size}) {
            $self->pop;        
        }
    }

    sub pop {
        my ($self) = @_;
        shift @{ $self->{$__q} };
    }

    1;

The two queue implementations are very similar, both containing a "q" attribute, the "size" and "pop" methods. The "push" methods are almost the same, the fixed size version just containing some extra logic after adding the item.

We can use a role to factor out the commonality of the two implementations:

    package Example::Roles::Role::Queue;

    use Minions::Role
        has  => {
            q => { default => sub { [ ] } },
        }, 
        semiprivate => ['after_push'],
    ;

    sub size {
        my ($self) = @_;
        scalar @{ $self->{$__q} };
    }

    sub push {
        my ($self, $val) = @_;

        push @{ $self->{$__q} }, $val;

        $self->{$__}->after_push($self);
    }

    sub pop {
        my ($self) = @_;
        shift @{ $self->{$__q} };
    }

    sub after_push { }

    1;

The role provides the  "q" attribute, the "size", "pop" and "push" methods, as well as a do nothing semiprivate "after_push" method.

Now using this role, the Queue implementation can be simplified to this:

    package Example::Roles::Acme::Queue_v2;

    use Minions::Implementation
        roles => ['Example::Roles::Role::Queue']
    ;

    1;

And the FixedSizeQueue implementation can be simplified to this:

    package Example::Roles::Acme::FixedSizeQueue_v2;

    use Minions::Implementation
        has  => {
            max_size => { 
                init_arg => 'max_size',
            },
        }, 
        semiprivate => ['after_push'],
        roles => ['Example::Roles::Role::Queue']
    ;

    sub after_push {
        my (undef, $self) = @_;

        if ($self->size > $self->{$__max_size}) {
            $self->pop;        
        }
    }

    1;

This implementation provides its own "after_push" method, so it does not get the one provided by the role.

To test these new implementations, we don't even need to update the main classes because we can re-bind them to new implementations quite easily:

    use strict;
    use Test::More;

    use Minions
        bind => { 
            'Example::Roles::FixedSizeQueue' 
              => 'Example::Roles::Acme::FixedSizeQueue_v2' 
        };
    use Example::Roles::FixedSizeQueue;

    my $q = Example::Roles::FixedSizeQueue->new(max_size => 3);

    $q->push($_) for 1 .. 3;
    is $q->size => 3;

    $q->push($_) for 4 .. 6;
    is $q->size => 3;
    is $q->pop => 4;
    done_testing();

=head2 Using multiple roles

An implementation can get its functionality from more than one role. As an example consider adding logging of the size as was done in L<Minions::Implementation/PRIVATE ROUTINES>.

Such functionality does not logically belong in the queue role, but we could create a new role for it

    package Example::Roles::Role::LogSize;

    use Minions::Role
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

Now we can use this role too

    package Example::Roles::Acme::FixedSizeQueue_v3;

    use Minions::Implementation
        has  => {
            max_size => { 
                init_arg => 'max_size',
            },
        }, 
        semiprivate => ['after_push'],
        roles => [qw/
            Example::Roles::Role::Queue
            Example::Roles::Role::LogSize
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

And use the queue like this

    % reply -I t/lib
    0> use Minions bind => { 'Example::Roles::FixedSizeQueue' => 'Example::Roles::Acme::FixedSizeQueue_v3' }
    1> use Example::Roles::FixedSizeQueue
    2> my $q = Example::Roles::FixedSizeQueue->new(max_size => 2)
    $res[0] = bless( {
             '2d395d65-' => 'Example::Roles::FixedSizeQueue::__Private',
             '2d395d65-max_size' => 2,
             '2d395d65-q' => []
           }, 'Example::Roles::FixedSizeQueue::__Minions' )

    3> $q->push(1)
    [Tue Jan 20 11:52:28 2015] I have 1 element(s)
    $res[1] = 1

    4> $q->can
    $res[2] = [
      'pop',
      'push',
      'size'
    ]

    5> $q->DOES
    $res[3] = [
      'Example::Roles::FixedSizeQueue',
      'Example::Roles::Role::LogSize',
      'Example::Roles::Role::Queue'
    ]

    6>

The last two commands show L<Minions>' support for introspection.
