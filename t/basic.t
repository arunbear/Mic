use strict;
use Test::Simpler tests => 7;
use Test::More ();
use Minion;

*explain = \&Test::More::explain;
*diag = \&Test::More::diag;

my %Class = (
    has  => {
        count => { default => 0 },
    }, 
    methods => {
        next => sub {
            my ($self) = @_;

            $self->{__count}++;
        }
    },
);

my $counter = Minion->minionize(\%Class)->new;

ok $counter->next == 0;
ok $counter->next == 1;
ok $counter->next == 2;

# Now create a named class

my %Named_class = (
    name => 'Counter',
    has  => {
        count => { default => 0 },
    }, 
    methods => {
        next => sub {
            my ($self) = @_;

            $self->{__count}++;
        }
    },
);
Minion->minionize(\%Named_class);
my $counter2 = Counter->new;

ok $counter2->isa('Counter');
ok $counter2->next == 0;
ok $counter2->next == 1;
ok $counter2->next == 2;
