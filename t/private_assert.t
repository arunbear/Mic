use strict;
use Test::Lib;
use Test::Most;
use Class::Minion ();

{
    package CounterImpl;
    use Scalar::Util;

    our %__Meta = (
        has  => {
            count => {
                default => 0,
                assert  => {
                    integer => sub { Scalar::Util::looks_like_number($_[0]) && $_[0] == int $_[0] },
                },
            },
        }, 
    );
    
    our $Count = 0;

    sub BUILD {
        my (undef, $self, $arg) = @_;

        $self->{'!'}->ASSERT('count', $arg->{start});
        $self->{$$}{count} = $arg->{start};
    }
    
    sub next {
        my ($self) = @_;

        $self->{$$}{count}++;
    }
}

{
    package Counter;

    our %__Meta = (
        interface => [qw( next )],
        implementation => 'CounterImpl',
    );
    Class::Minion->minionize;
}

package main;

throws_ok { my $counter = Counter->new() } 'Class::Minion::Error::AssertionFailure';
throws_ok { my $counter = Counter->new(start => 'asd') } 'Class::Minion::Error::AssertionFailure';
lives_ok  { my $counter = Counter->new(start => 1) } 'Parameter is valid';

done_testing();
