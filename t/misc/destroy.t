use strict;
use Test::Lib;
use Test::Most;

{
    package Process;
    use Moduloop ();

    Moduloop->assemble({
        interface => [qw( id )],
        implementation => 'ProcessImpl',
    });
}

{
    package ProcessImpl;

    use Moduloop::Imp
        has => { ID => { reader => 'id' } }
    ;
    
    our $Count = 0;

    sub BUILD {
        my (undef, $self) = @_;

        $self->{$ID} = ++$Count;
    }
    
    sub DESTROY {
        my ($self) = @_;
        --$Count;
    }
}

package main;

for ( 1 .. 3 ) {
    my $proc = Process->new();
    is($proc->id, 1);
}
is($ProcessImpl::Count, 0, 'All objects destroyed');

done_testing();
