use strict;
use Test::Simpler tests => 3;
use Minion;

my %Class = (
    name => 'Counter',
    has  => {
        count => { default => 0 },
    }, 
    methods => {
        next => sub {
            my ($self) = @_;

            $self->{count}++;
        }
    },
);

Minion->minionize(\ %Class);
my $counter = Counter->new;

ok $counter->next == 0;
ok $counter->next == 1;
ok $counter->next == 2;
