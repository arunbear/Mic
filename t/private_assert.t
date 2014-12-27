use strict;
use Test::Lib;
use Test::Most;
use Minions ();

BEGIN {
our %Assert = (is_integer => sub { Scalar::Util::looks_like_number($_[0]) && $_[0] == int $_[0] });
}

{
    package CounterImpl;
    use Scalar::Util;

    use Minions::Implementation
        has  => {
            count => {
                default => 0,
                assert  => { %main::Assert },
            },
            step => {
                init_arg => 'step',
            }
        }, 
    ;
    
    our $Count = 0;

    sub BUILD {
        my (undef, $self, $arg) = @_;

        $self->{'!'}->ASSERT('count', $arg->{start});
        $self->{'!'}->ASSERT('step',  $arg->{-step}) if $arg->{-step};
        # use Data::Dump 'pp'; die pp($self);
        $self->{$__Count} = $arg->{start};
    }
    
    sub next {
        my ($self) = @_;

        $self->{$__Count}++;
    }
}

{
    package Counter;

    our %__meta__ = (
        interface => [qw( next )],
        construct_with => {
            #TODO: fix to allow just these keys
            step => {
                optional => 1,
                assert  => { %main::Assert },
            }
        },
        implementation => 'CounterImpl',
    );
    Minions->minionize;
}

package main;

throws_ok { my $counter = Counter->new() } 'Minions::Error::AssertionFailure';
throws_ok { my $counter = Counter->new(start => 'asd') } 'Minions::Error::AssertionFailure';
throws_ok { my $counter = Counter->new(start => 1, step => 'asd') } 'Minions::Error::AssertionFailure';
throws_ok { my $counter = Counter->new(start => 1, -step => 'asd') } 'Minions::Error::AssertionFailure';
lives_ok  { my $counter = Counter->new(start => 1) } 'Parameter is valid';

done_testing();
