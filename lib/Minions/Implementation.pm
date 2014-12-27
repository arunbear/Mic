package Minions::Implementation;

use strict;
use Minions::_Guts;
use Package::Stash;
use Readonly;

sub import {
    my ($class, %arg) = @_;

    strict->import();

    $arg{-caller} = (caller)[0];
    $class->define(%arg);
}

sub define {
    my ($class, %arg) = @_;
    
    my $caller_pkg = delete $arg{-caller} || (caller)[0];
    my $stash = Package::Stash->new($caller_pkg);
    
    $class->update_args(\%arg);
    $class->add_attribute_syms(\%arg, $stash);
    
    $stash->add_symbol('%__meta__', \%arg);
}

sub add_attribute_syms {
    my ($class, $arg, $stash) = @_;

    foreach my $slot (keys %{ $arg->{has} }) {
        $class->add_obfu_name($arg, $stash, $slot);
    }

    foreach my $slot (@{ $arg->{requires}{attributes} || [] }) {
        $class->add_obfu_name($arg, $stash, $slot);
    }
}

sub add_obfu_name {
    my ($class, $arg, $stash, $slot) = @_;

    Readonly my $sym_val => "$Minions::_Guts::attribute_sym-$slot"; 
    $Minions::_Guts::obfu_name{$slot} = $sym_val;

    $stash->add_symbol(
        sprintf('$%s%s', $arg->{attribute_sym_prefix} || '__', ucfirst $slot),
        \ $sym_val
    );
}

sub update_args {}

1;
