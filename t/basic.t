use strict;
use Test::Most tests => 7;
use Minion;

my %Class = (
    interface => [qw(new next)],
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

is($counter->next, 0);
is($counter->next, 1);
is($counter->next, 2);

# Now create a named class

my %Named_class = (
    name => 'Counter',
    interface => [qw(new next)],
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

isa_ok($counter2, 'Counter::__Minion');
is($counter2->next, 0);
is($counter2->next, 1);
is($counter2->next, 2);
