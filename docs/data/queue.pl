#!/usr/bin/perl

use strict;
use warnings;

# 대기열의 평균 길이를 구해 보자.
# 창구는 1개, $n시간 동안 열려 있다.
my $n = 8;
# 손님이 방문할 확률은 $p 이고 동시에 $k명까지 방문한다.
# my $p = 0.05;
my $p = 0.1;
my $k = 5;
# 창구의 고객 처리 시간은 $d분 이다.
my $d = 3;

my $idle_tick = 0;
my $waiting = 0;
my @total_ticks = (1..$n*60);
my $total_waiting_customer = 0;
foreach my $tick ( @total_ticks ){
    my $neo_customer = 0;
    foreach ( (1..$k) ){
	if( rand(1) <= $p){
	    $neo_customer ++;
	}
    }
    $waiting += ($neo_customer * $d);
    if($waiting > 0){
	$waiting --;
    }
    my $waiting_customer = 0;
    if($waiting > 0){
	$waiting_customer = int(($waiting -1) / $d) + 1;
    }
    if($waiting == 0){
	$idle_tick ++;
    }
    $total_waiting_customer += $waiting_customer;

    my $hour = 0;
    $hour = int($tick/60);
    my $minute = $tick - $hour * 60;

    printf "%02d:%02d [%4d] %3d명 대기 (신규 %d명)\n", $hour, $minute, $waiting, $waiting_customer, $neo_customer;
}
my $total_tick = scalar(@total_ticks);
printf "working ratio %.2f %d/%d, 평균 대기인 %.2f\n", 100*($total_tick - $idle_tick)/$total_tick, $total_tick - $idle_tick, $total_tick, $total_waiting_customer/$total_tick;
