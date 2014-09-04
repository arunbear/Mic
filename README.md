# NAME

Minion - build and organise minions declaratively.

# SYNOPSIS

      # Create and use a class
      
      use Test::Most tests => 4;
      use Minion;
      
      my %Class = (
          interface => [qw( next )],
          implementation => {
              methods => {
                  next => sub {
                      my ($self) = @_;
      
                      $self->{__count}++;
                  }
              },
              has  => {
                  count => { default => 0 },
              }, 
          },
      );
      
      my $counter = Minion->minionize(\%Class)->new;
      
      is $counter->next => 0;
      is $counter->next => 1;
      is $counter->next => 2;
      
      throws_ok { $counter->new } qr/Can't locate object method "new"/;
      
      
      # Like above but give the class a name
    
      use Test::Most tests => 4;
      use Minion;
      
      my %Class = (
          name => 'Counter',
          interface => [qw( next )],
          implementation => {
              methods => {
                  next => sub {
                      my ($self) = @_;
      
                      $self->{__count}++;
                  }
              },
              has  => {
                  count => { default => 0 },
              }, 
          },
      );
      
      Minion->minionize(\%Class);
      my $counter = Counter->new;
      
      is $counter->next => 0;
      is $counter->next => 1;
      
      throws_ok { $counter->new } qr/Can't locate object method "new"/;
      throws_ok { Counter->next } qr/Can't locate object method "next" via package "Counter"/;
      
      
      # Or put code in packages
      
      package Example::Synopsis::Counter;
      
      use strict;
      use Minion;
      
      our %__Meta = (
          interface => [qw( next )],
          implementation => 'Example::Synopsis::Acme::Counter',
      );
      Minion->minionize;  
      
      # In a script near by ...
      
      use Test::Most tests => 3;
      use Example::Synopsis::Counter;
      
      my $counter = Example::Synopsis::Counter->new;
      
      is $counter->next => 0;
      is $counter->next => 1;
      is $counter->next => 2;
      
      # And the implementation for this class:
      
      package Example::Synopsis::Acme::Counter;
      
      use strict;
      
      our %__Meta = (
          has  => {
              count => { default => 0 },
          }, 
      );
      
      sub next {
          my ($self) = @_;
      
          $self->{__count}++;
      }
      
      1;    
      

# DESCRIPTION

Minion is a class builder oriented towards interface driven programming.

# AUTHOR

Arun Prasaad <arunbear@cpan.org>

# COPYRIGHT

Copyright 2014- Arun Prasaad

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v3.

# SEE ALSO
