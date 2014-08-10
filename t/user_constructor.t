use strict;
use Test::Simpler tests => 3;
use Minion;

my %Class = (
    interface => [qw(new next)],
    has  => {
        count => { default => 0 },
    }, 
    methods => {
        new => sub {
            my ($class, $start) = @_;

            my $obj = $class->__new__;
            $obj->{__count} = $start;
            return $obj;
        },
        next => sub {
            my ($self) = @_;

            $self->{__count}++;
        }
    },
);

my $counter = Minion->minionize(\%Class)->new(1);

ok $counter->next == 1;
ok $counter->next == 2;
ok $counter->next == 3;
