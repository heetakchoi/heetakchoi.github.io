package EohCalc;

use strict;
use warnings;

use Math::BigInt;

use Exporter;
use vars qw( @ISA @EXPORT_OK $VERSION );

@ISA = qw( Exporter );
@EXPORT_OK = qw( factorial permutation combination );
$VERSION = "0.1";

sub combination{
    my $n = $_[0];
    my $r = $_[1];
    return permutation($n, $r)->bdiv(factorial($r));
}

sub permutation{
    my $n = $_[0];
    my $r = $_[1];
    my $result = Math::BigInt->new("1");
    my @elements = (1..$r);
    foreach my $element (@elements){
	$result = $result->bmul( $n-$element+1 );
    }
    return $result;
}

sub factorial{
    my $n = $_[0];
    return permutation($n, $n);
}

return "EohCalc.pm";
