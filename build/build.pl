#!/usr/bin/perl

use strict;
use warnings;

use lib "../../volken/lib";
use Volken::Mark;

sub get_array_from_file;
sub article_srno;
sub book_srno;

my $mark;

my @base_lines = get_array_from_file("../template/base.html");
my @article_lines = get_array_from_file("../template/article.html");
my @book_lines = get_array_from_file("../template/book.html");

################################################################################
#  info article
my %article_hash = map { article_srno($_)=>$_ } grep /\/articles\/\d+\.txt$/, glob "../data/articles/*.txt";
my @article_srnos = reverse sort {$a<=>$b} keys %article_hash;
my $latest_article_link = "<a onclick=\"javascript:move_to_latest_article();\">Articles</a>";
my $latest_article_link_indepth = "<a onclick=\"javascript:move_to_latest_article_indepth();\">Articles</a>";
#  info book
my %book_hash = map { book_srno($_)=>$_ } grep /\/books\/\d+\.txt$/, glob "../data/books/*.txt";
my @book_srnos = reverse sort {$a<=>$b} keys %book_hash;
my $latest_book_link = "<a onclick=\"javascript:move_to_latest_book();\">Books</a>";
my $latest_book_link_indepth = "<a onclick=\"javascript:move_to_latest_book_indepth();\">Books</a>";
################################################################################
# make script.js
my $latest_article_srno = $article_srnos[0];
my $latest_book_srno = $book_srnos[0];
my $script_document = <<"END_DOCUMENT";
function move_to_latest_article(){
    document.location = "articles/article-$latest_article_srno.html";
}
function move_to_latest_article_indepth(){
    document.location = "../articles/article-$latest_article_srno.html";
}
function move_to_latest_book(){
    document.location = "books/book-$latest_book_srno.html";
}
function move_to_latest_book_indepth(){
    document.location = "../books/book-$latest_book_srno.html";
}

END_DOCUMENT

open my $fh, ">", "../docs/script.js";
print $fh $script_document;
close $fh;
################################################################################
# make index.html
# open $fh, ">", "../docs/index.html";
# print $fh "<script> document.location = 'https://endofhope.com'; </script>";
# close $fh;
################################################################################
# redirect to latest
open $fh, ">", "../docs/redirect_to_latest_article.html";
printf $fh "<script> document.location = \"articles/article-%s.html\"; </script>\n", $latest_article_srno;
close $fh;
open $fh, ">", "../docs/redirect_to_latest_book.html";
printf $fh "<script> document.location = \"books/book-%s.html\"; </script>\n", $latest_book_srno;
close $fh;
################################################################################
# write article down
my $index = -1;
foreach my $article_srno (@article_srnos){
    $index ++;
    $mark = Volken::Mark->new->load_file($article_hash{$article_srno});
    my $main_string = "";
    foreach (@article_lines){
	if(/____(\w+)____/){
	    if($1 eq "ARTICLE"){
		$main_string .= $mark->get_html();
	    }elsif($1 eq "PREV"){
		if($index >0){
		    $main_string .= sprintf "<a href=\"article-%d.html\">이전 글 가기</a>", $article_srnos[$index-1];
		}else{
		    $main_string .= "최신 글 입니다.";
		}
	    }elsif($1 eq "PADDING"){
		$main_string .= sprintf " &nbsp; &nbsp; ";
	    }elsif($1 eq "NEXT"){
		if($index < $#article_srnos){
		    $main_string .= sprintf "<a href=\"article-%d.html\">다음 글 보기</a>", $article_srnos[$index+1];
		}else{
		    $main_string .= "첫 글 입니다.";
		}
		$main_string .= "\n";
	    }else{
		die "[".$1."] 은 기대하지 않은 값. A\n";
	    }
	}else{
	    $main_string .= $_;
	}
    }

    my $articlefile = sprintf "../docs/articles/article-%d.html", $article_srno;
    open(my $fh_article, ">", $articlefile);
    foreach (@base_lines){
	if(/____(\w+)____/){
	    if($1 eq "TITLE"){
		print $fh_article "Life Logging - Article ", $article_srno, "\n";
	    }elsif($1 eq "MAIN"){
		print $fh_article $main_string;
	    }elsif($1 eq "SCRIPT"){
		print $fh_article "<script src=\"../script.js\"></script>", "\n";
	    }elsif($1 eq "STYLESHEET"){
		print $fh_article "<link rel=\"stylesheet\" href=\"../style.css\" />", "\n";
	    }elsif($1 eq "MENUINDEX"){
		print $fh_article "<a href=\"../index.html\">Home</a>", "\n";
	    }elsif($1 eq "MENUARTICLE"){
		print $fh_article $latest_article_link_indepth, "\n";
	    }elsif($1 eq "MENUSF"){
		print $fh_article "<a href=\"../sf.html\">SF</a>", "\n";
	    }elsif($1 eq "MENUINFO"){
		print $fh_article "<a href=\"../info.html\">Info</a>", "\n";
	    }elsif($1 eq "MENUBOOK"){
		print $fh_article $latest_book_link_indepth, "\n";
	    }else{
		die "[".$1."] 는 기대하지 않은 값. B\n";
	    }
	}else{
	    print $fh_article $_;
	}
    }
    close($fh_article);
}
################################################################################
# write book down
$index = -1;
foreach my $book_srno (@book_srnos){
    $index ++;
    $mark = Volken::Mark->new->load_file($book_hash{$book_srno});
    my $main_string = "";
    foreach (@book_lines){
	if(/____(\w+)____/){
	    if($1 eq "BOOK"){
		$main_string .= $mark->get_html();
	    }elsif($1 eq "PREV"){
		if($index >0){
		    $main_string .= sprintf "<a href=\"book-%d.html\">이전 글 가기</a>", $book_srnos[$index-1];
		}else{
		    $main_string .= "최신입니다.";
		}
	    }elsif($1 eq "PADDING"){
		$main_string .= sprintf " &nbsp; &nbsp; ";
	    }elsif($1 eq "NEXT"){
		if($index < $#book_srnos){
		    $main_string .= sprintf "<a href=\"book-%d.html\">다음 글 보기</a>", $book_srnos[$index+1];
		}else{
		    $main_string .= "첫 글 입니다.";
		}
		$main_string .= "\n";
	    }else{
		die "[".$1."] 은 기대하지 않은 값. C\n";
	    }
	}else{
	    $main_string .= $_;
	}
    }

    my $bookfile = sprintf "../docs/books/book-%d.html", $book_srno;
    open(my $fh_book, ">", $bookfile);
    foreach (@base_lines){
	if(/____(\w+)____/){
	    if($1 eq "TITLE"){
		print $fh_book "Life Logging - Book ", $book_srno, "\n";
	    }elsif($1 eq "MAIN"){
		print $fh_book $main_string;
	    }elsif($1 eq "SCRIPT"){
		print $fh_book "<script src=\"../script.js\"></script>", "\n";
	    }elsif($1 eq "STYLESHEET"){
		print $fh_book "<link rel=\"stylesheet\" href=\"../style.css\" />", "\n";
	    }elsif($1 eq "MENUINDEX"){
		print $fh_book "<a href=\"../index.html\">Home</a>", "\n";
	    }elsif($1 eq "MENUARTICLE"){
		print $fh_book $latest_article_link_indepth, "\n";
	    }elsif($1 eq "MENUSF"){
		print $fh_book "<a href=\"../sf.html\">SF</a>", "\n";
	    }elsif($1 eq "MENUINFO"){
		print $fh_book "<a href=\"../info.html\">Info</a>", "\n";
	    }elsif($1 eq "MENUBOOK"){
		print $fh_book $latest_book_link_indepth, "\n";
	    }else{
		die "[".$1."] 는 기대하지 않은 값. D\n";
	    }
	}else{
	    print $fh_book $_;
	}
    }
    close($fh_book);
}
################################################################################
# index-file, info-file, sf-file 을 만든다.
# data/font, data/info, data/sf 파일을 읽어들인 후 포매팅을 한 후, tmpl의 placeholder에 끼워 넣는다.
$mark = Volken::Mark->new->load_file("../data/front.txt");
my $indexcontent = $mark->get_html();
$indexcontent =~ s/__ARTICLELINK__/$latest_article_link/g;
$indexcontent =~ s/__BOOKLINK__/$latest_book_link/g;
$mark = Volken::Mark->new->load_file("../data/info.txt");
my $infocontent = $mark->get_html();
$mark = Volken::Mark->new->load_file("../data/sf.txt");
my $sfcontent = $mark->get_html();
open(my $fh_index, ">", "../docs/index.html");
open(my $fh_info, ">", "../docs/info.html");
open(my $fh_sf, ">", "../docs/sf.html");
my @handlers = ($fh_index, $fh_info, $fh_sf);
    foreach my $line (@base_lines){
	if($line =~ /____(\w+)____/){
	    if($1 eq "TITLE"){
		print $fh_index "Life Logging - INDEX", "\n";
		print $fh_info "Life Logging - INFO", "\n";
		print $fh_sf "Life Logging - SF", "\n";
	    }elsif($1 eq "MAIN"){
		print $fh_index $indexcontent;
		print $fh_info $infocontent;
		print $fh_sf $sfcontent;
	    }elsif($1 eq "SCRIPT"){
		map { print $_ "<script src=\"script.js\"></script>", "\n"} @handlers;
	    }elsif($1 eq "STYLESHEET"){
		map { print $_ "<link rel=\"stylesheet\" href=\"style.css\" />", "\n"} @handlers;
	    }elsif($1 eq "MENUINDEX"){
		map { print $_ "<a href=\"index.html\">Home</a>", "\n"} @handlers;
	    }elsif($1 eq "MENUARTICLE"){
		map { print $_ $latest_article_link, "\n"} @handlers;
	    }elsif($1 eq "MENUSF"){
		map { print $_ "<a href=\"sf.html\">SF</a>", "\n"} @handlers;
	    }elsif($1 eq "MENUINFO"){
		map { print $_ "<a href=\"info.html\">Info</a>", "\n"} @handlers;
	    }elsif($1 eq "MENUBOOK"){
		map { print $_ $latest_book_link, "\n";} @handlers;
	    }else{
		die "[".$1."] 는 기대하지 않은 값. E\n";
	    }
	}else{
	    map { print $_ $line } @handlers;
	}
}
close($fh_index);
close($fh_info);
close($fh_sf);

sub get_array_from_file{
    my ($filename) = @_;
    my @lines = ();
    open(my $fh, "<", $filename);
    while(<$fh>){
	push(@lines, $_);
    }
    close($fh);
    return @lines;
}
sub article_srno{
    my ($article_name) = @_;
    $article_name =~ /\/articles\/(\d+)\.txt$/;
    return $1;
}
sub book_srno{
    my ($book_name) = @_;
    $book_name =~ /\/books\/(\d+)\.txt$/;
    return $1;
}
