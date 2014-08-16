package Minion;

use strict;
use 5.008_005;
use Carp;
use Hash::Util qw( lock_keys );
use Module::Runtime qw( require_module );
use Package::Stash;

our $VERSION = 0.000_001;

my $Class_count = 0;

sub minionize {
    my (undef, $spec) = @_;

    my $stash;
    if ( ! $spec ) {
        my $caller_pkg = (caller)[0];
        $stash = Package::Stash->new($caller_pkg);
        $spec  = $stash->get_symbol('%__Meta');
        $spec->{name} = $caller_pkg;
    }
    $spec->{name} ||= "Minion::Class_${\ ++$Class_count }";
    $stash        ||= Package::Stash->new($spec->{name});
    
    my $obj_stash;

    if ( $spec->{implementation} && ! ref $spec->{implementation} ) {
        my $pkg = $spec->{implementation};
        $obj_stash = Package::Stash->new($pkg); # allow for inlined pkg

        if ( ! $obj_stash->has_symbol('%__Meta') ) {
            require_module($pkg);
            $obj_stash = Package::Stash->new($pkg);
        }
        $spec->{implementation} = { 
            package => $pkg, 
            has     => $obj_stash->get_symbol('%__Meta')->{has},
            methods => $obj_stash->get_all_symbols('CODE'),
        };
    }
    else {
        $obj_stash = Package::Stash->new("$spec->{name}::__Minion");
    }
    my $private_stash = Package::Stash->new("$spec->{name}::__Private");

    _add_object_maker($spec, $stash, $private_stash, $obj_stash);
    _add_class_methods($spec, $stash);
    _add_methods($spec, $obj_stash, $private_stash);
    return $spec->{name};
}

sub _add_object_maker {
    my ($spec, $stash, $private_stash, $obj_stash) = @_;

    $stash->add_symbol("&__new__", sub {
        shift;
        my %obj = ('!' => $private_stash->name);

        while ( my ($attr, $meta) = each %{ $spec->{implementation}{has} } ) {
            $obj{"__$attr"} = $meta->{default};
        }
        bless \ %obj => $obj_stash->name;            
        lock_keys(%obj);
        return \ %obj;
    });
}

sub _add_class_methods {
    my ($spec, $stash) = @_;

    if ( ! exists $spec->{class_methods}{new} ) {
        $spec->{class_methods}{new} = sub {
            my ($class) = @_;
            my $obj = $class->__new__;
            return $obj;
        };
    }
    foreach my $sub ( keys %{ $spec->{class_methods} } ) {
        $stash->add_symbol("&$sub", $spec->{class_methods}{$sub});
    }
}

sub _add_methods {
    my ($spec, $stash, $private_stash) = @_;

    my %in_interface = map { $_ => 1 } @{ $spec->{interface} };

    while ( my ($name, $sub) = each %{ $spec->{implementation}{methods} } ) {
        my $use_stash = $in_interface{$name} ? $stash : $private_stash;
        $use_stash->add_symbol("&$name", $sub);
    }
}

sub _privitise {
    my ($stash, $spec) = @_;

    my %in_interface = map { $_ => 1 } @{ $spec->{interface} };
    my $private_stash = Package::Stash->new($stash->name.'::Private');

    foreach my $meth ( keys %{ $spec->{methods} } ) {

        next if $meth eq 'new';
        if ( ! $in_interface{$meth} ) {
            my $sym = "&$meth";
            $private_stash->add_symbol($sym => $stash->get_symbol($sym));
            $stash->remove_symbol($sym);
        }
    }
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
