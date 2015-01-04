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

=head1 DESCRIPTION

Roles provide reusable implementation details, i.e. they solve the problem of what to do when the same implementation details are found in more than one implementation package.

=head1 CONFIGURATION

A role package can be configured either using Minions::Role or with a package variable C<%__meta__>. Both methods make use of the following keys:
 
=head2 role => 1 (Mandatory)

Only needed if Minions::Role is not used. This indicates that the package is a Role.

=head2 has => HASHREF

This works the same way as in an implementation package.

=for comment
=head2 semiprivate => ARRAYREF
This works the same way as in an implementation package.

=head2 requires => HASHREF

A hash with keys:

=head3 methods => ARRAYREF

Any methods listed here must be provided by an implementation package or a role.

=head3 attributes => ARRAYREF

Any attributes listed here must be provided by an implementation package or a role.

=head2 roles => ARRAYREF

A list of roles which the current role is composed out of.

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
