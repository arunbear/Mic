package Minion;

use strict;
use 5.008_005;
use Carp;
use Hash::Util qw( lock_keys );
use Package::Stash;

our $VERSION = 0.000_001;

my $Class_count = 0;

sub minionize {
    my (undef, $spec) = @_;

    my $class = $spec->{name}
      || "Minion::Class_${\ ++$Class_count }";
    
    my $stash = Package::Stash->new($class);

    if ( ! exists $spec->{methods}{new} ) {
        $spec->{methods}{new} = sub {
            my %obj;

            foreach my $attr ( keys %{ $spec->{has} } ) {
                $obj{"__$attr"} = $spec->{has}{default};
            }
            bless \ %obj => $class;            
            lock_keys(%obj);
            return \ %obj;
        };
    }

    foreach my $sub ( keys %{ $spec->{methods} } ) {
        $stash->add_symbol("&$sub", $spec->{methods}{$sub});
    }
    return $class;
}

1;
__END__

=encoding utf-8

=head1 NAME

Minion - build your minions.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Minion is library for building minions.

=head1 AUTHOR

Arun Prasaad E<lt>arunbear@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Arun Prasaad

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v3.

=head1 SEE ALSO

=cut
