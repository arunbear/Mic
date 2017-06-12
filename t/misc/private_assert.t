use strict;
use Test::Lib;
use Test::Most;

{
    package Counter;
    use Moduloop ();

    BEGIN {
        %Counter::Assert = (
            is_integer => sub { Scalar::Util::looks_like_number($_[0]) && $_[0] == int $_[0] }
        );
    }

    Moduloop->assemble({
        interface => [qw( next )],
        constructor => {
            kv_args => {
                start => {
                    optional => 1,
                },
                step => {
                    optional => 1,
                    callbacks  => { %Counter::Assert },
                },
                -step => {
                    optional => 1,
                },
            }
        },
        implementation => 'CounterImpl',
    });
}
{
    package CounterImpl;
    use Scalar::Util;

    use Moduloop::Implementation
        has  => {
            COUNT => {
                default => 0,
                callbacks => { %Counter::Assert },
            },
            STEP => {
                init_arg => 'step',
            },
        }, 
    ;
    
    our $Count = 0;

    sub BUILD {
        my (undef, $self, $arg) = @_;

        $self->{$__}->ASSERT('COUNT', $arg->{start}) if $arg->{start};
        $self->{$__}->ASSERT('STEP',  $arg->{-step}) if $arg->{-step};
        $self->{$COUNT} = $arg->{start};
    }
    
    sub next {
        my ($self) = @_;

        $self->{$COUNT}++;
    }
}


package main;

TODO: {
    local $TODO = "Will be retired, superseded by contracts";
    lives_ok { my $counter = Counter->new() } 'No params';
    throws_ok { my $counter = Counter->new(starr => 'asd') } qr/was not listed in the validation options: starr/;

    throws_ok { my $counter = Counter->new(start => 1, step => 'asd') } qr/The 'step' parameter .+ did not pass the 'is_integer' callback/;
    throws_ok { my $counter = Counter->new(start => 1, -step => 'asd') } qr/The 'STEP' parameter .+ did not pass the 'is_integer' callback/;
    throws_ok  { my $counter = Counter->new(start => 'abc') } qr/The 'COUNT' parameter .+ did not pass the 'is_integer' callback/;
    lives_ok  { my $counter = Counter->new(start => 1) } 'Parameter is valid';
}

done_testing();
