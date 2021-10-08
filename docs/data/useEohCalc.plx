#!/usr/bin/perl

use strict;
use warnings;

use Math::BigFloat;

use EohCalc ("factorial", "permutation", "combination" );

my @rs = (204..300);

my $child = Math::BigFloat->new("0");

foreach my $r (@rs){
    $child = $child->badd(combination(300, $r));
}

my $mother = Math::BigFloat->new(2**300);

print $child->bdiv($mother);
print "\n";
