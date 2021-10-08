#!/usr/bin/perl

use strict;
use warnings;

sub biop;

my %hash = ();

foreach my $a ((0..9)){
    foreach my $b ((0..9)){
	foreach my $c ((0..9)){
	    foreach my $d ((0..9)){
		my @sorted = sort ($a, $b, $c, $d);
		my $key = sprintf "%d-%d-%d-%d",$sorted[0], $sorted[1], $sorted[2], $sorted[3];
		next if(defined($hash{$key}));

		my $exit_flag = 0;
		foreach my $x (("+","-","*","/")){
		    foreach my $y (("+","-","*","/")){
			foreach my $z (("+","-","*","/")){

			    # 123
			    my $r_123 = biop(biop(biop($a, $x, $b), $y, $c), $z, $d);
			    if($r_123 == 10){
				$hash{$key} = sprintf "%s, %f  ((%d %s %d) %s %d) %s %d", $key, $r_123, $a, $x, $b, $y, $c, $z, $d;
				$exit_flag = 1;
				last;
			    }
			    # 132
			    my $r_132 = biop(biop($a, $x, $b), $y, biop($c, $z, $d));
			    if($r_132 == 10){
				$hash{$key} = sprintf "%s, %f  (%d %s %d) %s (%d %s %d)", $key, $r_132, $a, $x, $b, $y, $c, $z, $d;
				$exit_flag = 1;
				last;
			    }
			    # 213
			    my $r_213 = biop(biop($a, $x, biop($b, $y, $c)), $z, $d);
			    if($r_213 == 10){
				$hash{$key} = sprintf "%s, %f  (%d %s (%d %s %d)) %s %d", $key, $r_213, $a, $x, $b, $y, $c, $z, $d;
				$exit_flag = 1;
				last;
			    }
			    # 231
			    my $r_231 = biop($a, $x, biop(biop($b, $y, $c), $z, $d));
			    if($r_231 == 10){
				$hash{$key} = sprintf "%s, %f  %d %s ((%d %s %d) %s %d)", $key, $r_231, $a, $x, $b, $y, $c, $z, $d;
				$exit_flag = 1;
				last;
			    }
			    # 312
			    my $r_312 = $r_132;
			    # 321
			    my $r_321 = biop($a, $x, biop($b, $y, biop($c, $z, $d)));
			    if($r_321 == 10){
				$hash{$key} = sprintf "%s, %f  %d %s (%d %s (%d %s %d))", $key, $r_321, $a, $x, $b, $y, $c, $z, $d;
				$exit_flag = 1;
				last;
			    }
			    
			    last if($exit_flag);
			}
			last if($exit_flag);
		    }
		    last if($exit_flag);
		}
	    }
	}
    }
}

my @impossibles = ();
foreach my $a ((0..9)){
    foreach my $b ((0..9)){
	foreach my $c ((0..9)){
	    foreach my $d ((0..9)){
		my @sorted = sort ($a, $b, $c, $d);
		my $key = sprintf "%d-%d-%d-%d",$sorted[0], $sorted[1], $sorted[2], $sorted[3];
		
		if(!defined($hash{$key})){
		    push(@impossibles, $key);
		    printf "---- %d %d %d %d %s\n", $a, $b, $c, $d, "NO WAY";
		}else{
		    printf "%d %d %d %d %s\n", $a, $b, $c, $d, $hash{$key};
		}
	    }
	}
    }
}
foreach (sort @impossibles){
    $_ =~ m/(\d)-(\d)-(\d)-(\d)/;
    if($1 != 0 and $1 != $2 and $2 != $3 and $3 != $4){
	printf "PURE IMPOSSIBLES %s\n", $_;
    }
}


sub biop{
    my ($left, $op, $right) = @_;
    return 'inf' if($left == 'inf');
    return 'inf' if($right == 'inf');
    if($op eq "+"){
	return $left + $right;
    }elsif($op eq "-"){
	return $left - $right;
    }elsif($op eq "*"){
	return $left * $right;
    }elsif($op eq "/"){
	if($right == 0){
	    return 'inf';
	}
	return $left / $right;
    }
    return 0;
}
