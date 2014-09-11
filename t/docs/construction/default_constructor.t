{
    package Example::Construction::Set;
    
    use strict;
    use Minion;
    
    our %__Meta = (
        interface => [qw( add has )],
        
        implementation => 'Example::Construction::Acme::Set',
    );
    Minion->minionize;
}

BEGIN {
    package Example::Construction::Acme::Set;
    
    use strict;
    
    our %__Meta = (
        has => { set => { default => sub { {} } } },
    );
    
    sub has {
        my ($self, $e) = @_;
        exists $self->{__set}{$e};
    }
    
    sub add {
        my ($self, $e) = @_;
        ++$self->{__set}{$e};
    }
    
    1;
}

{
    
    package main;
    use Test::More tests => 2;
    
    my $set = Example::Construction::Set->new;
    
    ok ! $set->has(1);
    $set->add(1);
    ok $set->has(1);
}