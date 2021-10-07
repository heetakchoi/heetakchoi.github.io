#!/usr/bin/perl

use strict;
use warnings;

use lib "../../volken/lib";
use Volken::Mark;

sub article_srno;

my $fh;
my @skeleton_lines = ();
open($fh, "<", "../template/skeleton.html");
while(<$fh>){
    push(@skeleton_lines, $_);
}
close($fh);

my @article_lines = ();
open($fh, "<", "../template/article.html");
while(<$fh>){
    push(@article_lines, $_);
}
close($fh);

my $mark;

# article
my %article_hash = map { article_srno($_)=>$_ } grep /\/articles\/\d+\.txt$/, glob "../data/articles/*.txt";
my @article_srnos = reverse sort {$a<=>$b} keys %article_hash;
my $latest_article_link = sprintf "<a href=\"article-%d.html\">Article</a>", $article_srnos[0];

my $index = -1;
foreach my $article_srno (@article_srnos){
    $index ++;
    $mark = Volken::Mark->new->load_file($article_hash{$article_srno});
    my $main_string = "";
    foreach (@article_lines){
	if(/____(\w+)_/){
	    if($1 eq "ARTICLE"){
		$main_string .= $mark->get_html();
	    }elsif($1 eq "PREV"){
		if($index >0){
		    $main_string .= sprintf "<a href=\"article-%d.html\">이전 글 가기</a>", $article_srnos[$index-1];
		}else{
		    $main_string .= "최신 글 입니다.";
		}
	    }elsif($1 eq "PADDING"){
		# $main_string .= sprintf " %d ", $article_srno;
		$main_string .= sprintf " &nbsp; &nbsp; ";
	    }elsif($1 eq "NEXT"){
		if($index < $#article_srnos){
		    $main_string .= sprintf "<a href=\"article-%d.html\">다음 글 보기</a>", $article_srnos[$index+1];
		}else{
		    $main_string .= "첫 글 입니다.";
		}
	    }else{
		die "____".$1."_ 은 기대하지 않은 값. A\n";
	    }
	}else{
	    $main_string .= $_;
	}
    }

    my $articlefile = sprintf "../docs/article-%d.html", $article_srno;
    open(my $fh_article, ">", $articlefile);
    foreach (@skeleton_lines){
	if(/____(\w+)_/){
	    if($1 eq "MAIN"){
		print $fh_article $main_string;
	    }elsif($1 eq "ARTICLELINK"){
		printf $fh_article $latest_article_link;
	    }else{
		die "____".$1."_ 은 기대하지 않은 값. B\n";
	    }
	}else{
	    print $fh_article $_;
	}
    }
    close($fh_article);
}

# front-file, info-file, sf-file 을 만든다.
# data/front, data/info, data/sf 파일을 읽어들인 후 포매팅을 한 후, tmpl의 placeholder에 끼워 넣는다.
$mark = Volken::Mark->new->load_file("../data/front.txt");
my $frontcontent = $mark->get_html();
$mark = Volken::Mark->new->load_file("../data/info.txt");
my $infocontent = $mark->get_html();
$mark = Volken::Mark->new->load_file("../data/sf.txt");
my $sfcontent = $mark->get_html();

open(my $fh_index, ">", "../docs/index.html");
open(my $fh_info, ">", "../docs/info.html");
open(my $fh_sf, ">", "../docs/sf.html");
foreach (@skeleton_lines){
    if(/____(\w+)_/){
	if($1 eq "MAIN"){
	    print $fh_index $frontcontent;
	    print $fh_info $infocontent;
	    print $fh_sf $sfcontent;
	}elsif($1 eq "ARTICLELINK"){
	    print $fh_index $latest_article_link;
	    print $fh_info $latest_article_link;
	    print $fh_sf $latest_article_link;
	}else{
	    die "____".$1."_ 은 기대하지 않은 값. C\n";
	}
    }else{
	print $fh_index $_;
	print $fh_info $_;
	print $fh_sf $_;
    }
}
close($fh_index);
close($fh_info);
close($fh_sf);

sub article_srno{
    my ($article_name) = @_;
    $article_name =~ /\/articles\/(\d+)\.txt$/;
    return $1;
}
