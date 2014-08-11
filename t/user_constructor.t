use strict;
use Test::More;
use Minion;

my %Class = (
    interface => [qw(next)],
    has  => {
        count => { default => 0 },
    }, 
    class_methods => {
        new => sub {
            my ($class, $start) = @_;

            my $obj = $class->__new__;
            $obj->{__count} = $start;
            return $obj;
        },
    },
    methods => {
        next => sub {
            my ($self) = @_;

            $self->{__count}++;
        }
    },
);

my $counter = Minion->minionize(\%Class)->new(1);

is($counter->next, 1);
is($counter->next, 2);
is($counter->next, 3);
done_testing();
