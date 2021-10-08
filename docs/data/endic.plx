#!/usr/bin/perl

use strict;
use warnings;

use Encode;
use LWP::Simple;
use XML::DOM;

sub main;
sub set_environment;
sub query_data;
sub create_dom;
sub cleanup_dom;
sub print_dom;
sub change_enc;
sub print_msg;

my $search_key;
if ($#ARGV < 0) {
    print "Usage : endic.plx [english-word]\n";
    exit;
} elsif ($#ARGV > 1) {
    print "Too many argument.. $ARGV[0] is selected" . "\n";
    $search_key = shift(@ARGV);
    foreach my $arg (@ARGV) {
	print $arg . " ";
    }
    print "canceled." . "\n";
} else {
    $search_key = shift(@ARGV);
}

my $api_key;
my $kind;
my $result_count;
set_environment(\$api_key, \$kind, \$result_count);
my $page_no = 1;
my ($current_pageno, $total_page_size) = print_msg($api_key, $kind, $result_count, $search_key, $page_no);

while ($current_pageno < $total_page_size) {
    print "Page $current_pageno / $total_page_size\n";
    print "type n for next, p for previous, Enter to quit\n";
    my $input = <STDIN>;
    chomp($input);
    if ("n" eq $input) {
	$page_no ++;
	print_msg($api_key, $kind, $result_count, $search_key, $page_no);
    } elsif ("p" eq $input) {
	$page_no --;
	if ($page_no <1) {
	    print "invalid page no. try again" . "\n";
	    $page_no = 1;
	}
	print_msg($api_key, $kind, $result_count, $search_key, $page_no);

    } else {
	print "#" x 40 . "\n";
	last;
    }
}

##### subroutines #####
sub print_msg{
    my $query_result = query_data($api_key, $kind, $result_count, $search_key, $page_no);
    my $xml_doc = create_dom($query_result);
    ($current_pageno, $total_page_size) = print_dom($xml_doc, \*STDOUT, $result_count);
    cleanup_dom($xml_doc);
    return ($current_pageno, $total_page_size);
}
sub print_dom{
    my $xml_doc = $_[0];
    my $file_handler = $_[1];
    my $result_bundle_size = $_[2];
    my $view_flag = $_[3];
    my $total_count_node = $xml_doc->getElementsByTagName("totalCount")->item(0);
    my $pageno_node = $xml_doc->getElementsByTagName("pageno")->item(0);
    my $result_count_node = $xml_doc->getElementsByTagName("result")->item(0);
    my $total_size = $total_count_node->getFirstChild()->getNodeValue();
    my $current_pageno = $pageno_node->getFirstChild()->getNodeValue();
    # my $result_bundle_size = $result_count_node->getFirstChild()->getNodeValue();
    my $total_page_size;
    if ( $total_size / $result_bundle_size == int($total_size / $result_bundle_size)) {
	$total_page_size = $total_size / $result_bundle_size;
    } else {
	$total_page_size = int($total_size / $result_bundle_size) + 1;
    }

    if ($view_flag) {
	print $file_handler "total : " . $total_size . "\n";
	print $file_handler "current page : " . $current_pageno . "\n";
	print $file_handler "total page : " . $total_page_size . "\n";
    }
    my $item_nodes = $xml_doc->getElementsByTagName("item");
    my $item_nodes_size = $item_nodes->getLength();
    for (my $i=0; $i<$item_nodes_size; $i++) {
	my $one_item_node = $item_nodes->item($i);
	print "  [" . ((($current_pageno-1)*$result_bundle_size)+($i+1)) . "] ";
	for my $child_node ($one_item_node->getChildNodes()) {
	    if ($child_node->getNodeName() eq "title") {
		my $title = change_enc($child_node->getFirstChild()->getNodeValue());
		print $file_handler $title . " : ";
	    } elsif ($child_node->getNodeName() eq "description") {
		my $desc = change_enc($child_node->getFirstChild()->getNodeValue());
		print $file_handler $desc . "\n";
	    }
	}
    }
    if ($current_pageno == $total_page_size) {
	print $file_handler "Page $current_pageno / $total_page_size\n";
	print $file_handler "#"x40 . "\n";
    }
    return ($current_pageno, $total_page_size);
}
sub cleanup_dom{
    $_[0]->dispose();
}
sub create_dom{
    my $xml_string = $_[0];
    my $parser = new XML::DOM::Parser;
    return $parser->parse($xml_string);
}
sub query_data{
    my ($api_key, $kind, $result_count, $search_key, $page_no) = @_;
    my $url = "http://apis.daum.net/dic/endic?apikey=" . $api_key .
	"&kind=" . $kind . "&result=" . $result_count .
	"&output=xml&q=" . $search_key .
	"&pageno=" . $page_no;
    return get($url);
}
sub set_environment{
    ${$_[0]} = "d3b3c8fe22566e904b1b0b759c190736fe16e843";
    ${$_[1]} = "WORD";
    ${$_[2]} = 5;
    binmode STDOUT, ":utf8";
}
sub change_enc{
    return $_[0];
}
