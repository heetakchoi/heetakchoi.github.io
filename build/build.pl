#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../../volken/lib";
use Volken::Mark;

sub get_array_from_file;
sub article_srno;
sub book_srno;
sub clean_html_for_meta;
sub format_rss_date;

my $mark;

my @base_lines = get_array_from_file("../template/base.html");
my @article_lines = get_array_from_file("../template/article.html");
my @book_lines = get_array_from_file("../template/book.html");

# info article
my %article_hash = map { article_srno($_)=>$_ } grep /\/articles\/\d+\.txt$/, glob "../data/articles/*.txt";
my @article_srnos = reverse sort {$a<=>$b} keys %article_hash;

# info book
my %book_hash = map { book_srno($_)=>$_ } grep /\/books\/\d+\.txt$/, glob "../data/books/*.txt";
my @book_srnos = reverse sort {$a<=>$b} keys %book_hash;

# 메뉴 링크 고도화 (최신 글 바로 가기 링크는 그대로 유지하되, 주 헤더 메뉴는 목록 index.html로 유도)
my $latest_article_link = "<a href=\"articles/index.html\">Articles</a>";
my $latest_article_link_indepth = "<a href=\"../articles/index.html\">Articles</a>";

my $latest_book_link = "<a href=\"books/index.html\">Books</a>";
my $latest_book_link_indepth = "<a href=\"../books/index.html\">Books</a>";

my $latest_article_srno = $article_srnos[0];
my $latest_book_srno = $book_srnos[0];

# script.js 생성 (구버전 호환성을 유지하여 혹시 남겨진 redirect_to_latest_article.html 등에서 동작하도록)
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

# redirect 파일 유지
open $fh, ">", "../docs/redirect_to_latest_article.html";
printf $fh "<script> document.location = \"articles/article-%s.html\"; </script>\n", $latest_article_srno;
close $fh;
open $fh, ">", "../docs/redirect_to_latest_book.html";
printf $fh "<script> document.location = \"books/book-%s.html\"; </script>\n", $latest_book_srno;
close $fh;

# Sitemap에 포함될 모든 정적 URL 수집용 어레이
my @sitemap_urls = (
    "https://heetakchoi.github.io/index.html",
    "https://heetakchoi.github.io/info.html",
    "https://heetakchoi.github.io/sf.html",
    "https://heetakchoi.github.io/articles/index.html",
    "https://heetakchoi.github.io/books/index.html"
);

# RSS Feed 아이템 수집용 어레이
my @rss_items = ();

# 각 아티클 및 책 메타데이터 수집용 목록 (아카이브 인덱스 생성용)
my @article_meta_list = ();
my @book_meta_list = ();

################################################################################
# write article down
my $index = -1;
foreach my $article_srno (@article_srnos){
    $index ++;
    $mark = Volken::Mark->new->load_file($article_hash{$article_srno});
    
    # 아티클 메타 정보 추출 (첫 줄 제목, 둘째 줄 날짜)
    my $file_path = $article_hash{$article_srno};
    open(my $fh_file, "<:utf8", $file_path);
    my $raw_title = <$fh_file> || "";
    my $raw_date = <$fh_file> || "";
    close($fh_file);
    
    $raw_title =~ s/^h2\.\s*//;
    $raw_title =~ s/\s+$//;
    $raw_date =~ s/^h5\.\s*//;
    $raw_date =~ s/\s+$//;
    
    push @article_meta_list, {
        srno => $article_srno,
        title => $raw_title,
        date => $raw_date
    };

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

    # 본문 텍스트 클리닝 및 SEO용 요약 추출
    my $html_content = $mark->get_html();
    my $clean_desc = clean_html_for_meta($html_content);
    
    # RSS 아이템에 최신 15개 등록을 위해 정보 저장
    if (scalar(@rss_items) < 15) {
        push @rss_items, {
            title => $raw_title,
            link => "https://heetakchoi.github.io/articles/article-$article_srno.html",
            desc => $clean_desc,
            date => $raw_date
        };
    }

    push @sitemap_urls, "https://heetakchoi.github.io/articles/article-$article_srno.html";

    my $articlefile = sprintf "../docs/articles/article-%d.html", $article_srno;
    open(my $fh_article, ">:utf8", $articlefile);
    foreach (@base_lines){
	if(/____(\w+)____/){
	    if($1 eq "TITLE"){
			my $first_line = substr($mark->get_first_line(), 4);
			$first_line =~ s/<[^>]*>//g;
		print $fh_article "Life Logging - ", $first_line, "\n";
	    }elsif($1 eq "METATAGS"){
		print $fh_article "    <meta name=\"description\" content=\"$clean_desc\" />\n";
		print $fh_article "    <meta property=\"og:title\" content=\"Life Logging - $raw_title\" />\n";
		print $fh_article "    <meta property=\"og:description\" content=\"$clean_desc\" />\n";
		print $fh_article "    <meta property=\"og:type\" content=\"article\" />\n";
		print $fh_article "    <meta property=\"og:url\" content=\"https://heetakchoi.github.io/articles/article-$article_srno.html\" />\n";
	    }elsif($1 eq "MAIN"){
		print $fh_article $main_string;
	    }elsif($1 eq "SCRIPT"){
		print $fh_article "<script src=\"../script.js\"></script>\n<script src=\"../blog-core.js\"></script>", "\n";
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
    
    # 북 리뷰 메타 정보 추출
    my $file_path = $book_hash{$book_srno};
    open(my $fh_file, "<:utf8", $file_path);
    my $raw_title = <$fh_file> || "";
    my $raw_date = <$fh_file> || "";
    close($fh_file);
    
    $raw_title =~ s/^h2\.\s*//;
    $raw_title =~ s/\s+$//;
    $raw_date =~ s/^h5\.\s*//;
    $raw_date =~ s/\s+$//;
    
    push @book_meta_list, {
        srno => $book_srno,
        title => $raw_title,
        date => $raw_date
    };

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

    my $html_content = $mark->get_html();
    my $clean_desc = clean_html_for_meta($html_content);

    push @sitemap_urls, "https://heetakchoi.github.io/books/book-$book_srno.html";

    my $bookfile = sprintf "../docs/books/book-%d.html", $book_srno;
    open(my $fh_book, ">:utf8", $bookfile);
    foreach (@base_lines){
	if(/____(\w+)____/){
	    if($1 eq "TITLE"){
		print $fh_book "Life Logging - ", $raw_title, "\n";
	    }elsif($1 eq "METATAGS"){
		print $fh_book "    <meta name=\"description\" content=\"$clean_desc\" />\n";
		print $fh_book "    <meta property=\"og:title\" content=\"Life Logging - $raw_title\" />\n";
		print $fh_book "    <meta property=\"og:description\" content=\"$clean_desc\" />\n";
		print $fh_book "    <meta property=\"og:type\" content=\"article\" />\n";
		print $fh_book "    <meta property=\"og:url\" content=\"https://heetakchoi.github.io/books/book-$book_srno.html\" />\n";
	    }elsif($1 eq "MAIN"){
		print $fh_book $main_string;
	    }elsif($1 eq "SCRIPT"){
		print $fh_book "<script src=\"../script.js\"></script>\n<script src=\"../blog-core.js\"></script>", "\n";
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
# 📜 전체 목록(Archive) 인덱스 HTML 생성
# 1) Articles 목록
{
    my $archive_html = "<div class=\"archive-header\">총 " . scalar(@article_meta_list) . "개의 이야기가 공유되어 있습니다.</div>\n";
    # $archive_html .= "<div style=\"margin-bottom: 24px;\"><a href=\"article-$latest_article_srno.html\" class=\"b\">✨ 최신 생각 바로 읽기 (Go to Latest)</a></div>\n";
    $archive_html .= "<ul class=\"archive-list\">\n";
    foreach my $item (@article_meta_list) {
        $archive_html .= "  <li class=\"archive-item\">\n";
        $archive_html .= sprintf "    <div class=\"archive-title\"><a href=\"article-%d.html\">%s</a></div>\n", $item->{srno}, $item->{title};
        $archive_html .= sprintf "    <div class=\"archive-date\">%s</div>\n", $item->{date};
        $archive_html .= "  </li>\n";
    }
    $archive_html .= "</ul>\n";

    open(my $fh_archive, ">:utf8", "../docs/articles/index.html");
    foreach (@base_lines){
        if(/____(\w+)____/){
            if($1 eq "TITLE"){
                print $fh_archive "Life Logging - Articles Archive\n";
            }elsif($1 eq "METATAGS"){
                print $fh_archive "    <meta name=\"description\" content=\"Heetak Choi의 생각 조각 아카이브 전체 목록\" />\n";
                print $fh_archive "    <meta property=\"og:title\" content=\"Life Logging - Articles Archive\" />\n";
                print $fh_archive "    <meta property=\"og:type\" content=\"website\" />\n";
            }elsif($1 eq "MAIN"){
                print $fh_archive $archive_html;
            }elsif($1 eq "SCRIPT"){
                print $fh_archive "<script src=\"../script.js\"></script>\n<script src=\"../blog-core.js\"></script>\n";
            }elsif($1 eq "STYLESHEET"){
                print $fh_archive "<link rel=\"stylesheet\" href=\"../style.css\" />\n";
            }elsif($1 eq "MENUINDEX"){
                print $fh_archive "<a href=\"../index.html\">Home</a>\n";
            }elsif($1 eq "MENUARTICLE"){
                print $fh_archive $latest_article_link_indepth, "\n";
            }elsif($1 eq "MENUSF"){
                print $fh_archive "<a href=\"../sf.html\">SF</a>\n";
            }elsif($1 eq "MENUINFO"){
                print $fh_archive "<a href=\"../info.html\">Info</a>\n";
            }elsif($1 eq "MENUBOOK"){
                print $fh_archive $latest_book_link_indepth, "\n";
            }else{
                die "[".$1."] 는 기대하지 않은 값. Archive Article\n";
            }
        }else{
            print $fh_archive $_;
        }
    }
    close($fh_archive);
}

# 2) Books 목록
{
    my $archive_html = "<div class=\"archive-header\">총 " . scalar(@book_meta_list) . "권의 리뷰가 기록되어 있습니다.</div>\n";
    # $archive_html .= "<div style=\"margin-bottom: 24px;\"><a href=\"book-$latest_book_srno.html\" class=\"b\">✨ 최신 리뷰 바로 읽기 (Go to Latest)</a></div>\n";
    $archive_html .= "<ul class=\"archive-list\">\n";
    foreach my $item (@book_meta_list) {
        $archive_html .= "  <li class=\"archive-item\">\n";
        $archive_html .= sprintf "    <div class=\"archive-title\"><a href=\"book-%d.html\">%s</a></div>\n", $item->{srno}, $item->{title};
        $archive_html .= sprintf "    <div class=\"archive-date\">%s</div>\n", $item->{date};
        $archive_html .= "  </li>\n";
    }
    $archive_html .= "</ul>\n";

    open(my $fh_archive, ">:utf8", "../docs/books/index.html");
    foreach (@base_lines){
        if(/____(\w+)____/){
            if($1 eq "TITLE"){
                print $fh_archive "Life Logging - Books Archive\n";
            }elsif($1 eq "METATAGS"){
                print $fh_archive "    <meta name=\"description\" content=\"Heetak Choi의 독서 리뷰 아카이브 전체 목록\" />\n";
                print $fh_archive "    <meta property=\"og:title\" content=\"Life Logging - Books Archive\" />\n";
                print $fh_archive "    <meta property=\"og:type\" content=\"website\" />\n";
            }elsif($1 eq "MAIN"){
                print $fh_archive $archive_html;
            }elsif($1 eq "SCRIPT"){
                print $fh_archive "<script src=\"../script.js\"></script>\n<script src=\"../blog-core.js\"></script>\n";
            }elsif($1 eq "STYLESHEET"){
                print $fh_archive "<link rel=\"stylesheet\" href=\"../style.css\" />\n";
            }elsif($1 eq "MENUINDEX"){
                print $fh_archive "<a href=\"../index.html\">Home</a>\n";
            }elsif($1 eq "MENUARTICLE"){
                print $fh_archive $latest_article_link_indepth, "\n";
            }elsif($1 eq "MENUSF"){
                print $fh_archive "<a href=\"../sf.html\">SF</a>\n";
            }elsif($1 eq "MENUINFO"){
                print $fh_archive "<a href=\"../info.html\">Info</a>\n";
            }elsif($1 eq "MENUBOOK"){
                print $fh_archive $latest_book_link_indepth, "\n";
            }else{
                die "[".$1."] 는 기대하지 않은 값. Archive Book\n";
            }
        }else{
            print $fh_archive $_;
        }
    }
    close($fh_archive);
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

open(my $fh_index, ">:utf8", "../docs/index.html");
open(my $fh_info, ">:utf8", "../docs/info.html");
open(my $fh_sf, ">:utf8", "../docs/sf.html");
my @handlers = ($fh_index, $fh_info, $fh_sf);

foreach my $line (@base_lines){
	if($line =~ /____(\w+)____/){
	    if($1 eq "TITLE"){
		print $fh_index "Life Logging - INDEX", "\n";
		print $fh_info "Life Logging - INFO", "\n";
		print $fh_sf "Life Logging - SF", "\n";
	    }elsif($1 eq "METATAGS"){
		print $fh_index "    <meta name=\"description\" content=\"Heetak Choi의 개인 생각과 독서, 공학적 기록들이 모여 있는 블로그입니다.\" />\n";
		print $fh_index "    <meta property=\"og:title\" content=\"Life Logging - Home\" />\n";
		print $fh_index "    <meta property=\"og:description\" content=\"개인 생각과 독서, 공학적 기록이 공존하는 공간\" />\n";
		print $fh_index "    <meta property=\"og:type\" content=\"website\" />\n";
		
		print $fh_info "    <meta name=\"description\" content=\"Heetak Choi를 소개하는 페이지입니다.\" />\n";
		print $fh_info "    <meta property=\"og:title\" content=\"Life Logging - Info\" />\n";
		
		print $fh_sf "    <meta name=\"description\" content=\"SF 장르에 대한 개인적인 감상과 아카이빙\" />\n";
		print $fh_sf "    <meta property=\"og:title\" content=\"Life Logging - SF\" />\n";
	    }elsif($1 eq "MAIN"){
		print $fh_index $indexcontent;
		print $fh_info $infocontent;
		print $fh_sf $sfcontent;
	    }elsif($1 eq "SCRIPT"){
		map { print $_ "<script src=\"script.js\"></script>\n<script src=\"blog-core.js\"></script>", "\n"} @handlers;
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

################################################################################
# 🌐 Sitemap.xml 생성
open(my $fh_sitemap, ">:utf8", "../docs/sitemap.xml") or die "Cannot open sitemap.xml";
print $fh_sitemap "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $fh_sitemap "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n";
foreach my $url (@sitemap_urls) {
    print $fh_sitemap "  <url>\n";
    print $fh_sitemap "    <loc>$url</loc>\n";
    print $fh_sitemap "    <changefreq>weekly</changefreq>\n";
    print $fh_sitemap "    <priority>0.8</priority>\n";
    print $fh_sitemap "  </url>\n";
}
print $fh_sitemap "</urlset>\n";
close($fh_sitemap);

################################################################################
# 📡 RSS Feed (feed.xml) 생성
open(my $fh_feed, ">:utf8", "../docs/feed.xml") or die "Cannot open feed.xml";
print $fh_feed "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
print $fh_feed "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n";
print $fh_feed "<channel>\n";
print $fh_feed "  <title>Life Logging</title>\n";
print $fh_feed "  <link>https://heetakchoi.github.io/</link>\n";
print $fh_feed "  <description>Heetak Choi의 개인 생각 조각과 독서 리뷰</description>\n";
print $fh_feed "  <language>ko-kr</language>\n";
print $fh_feed "  <atom:link href=\"https://heetakchoi.github.io/feed.xml\" rel=\"self\" type=\"application/rss+xml\" />\n";

foreach my $item (@rss_items) {
    my $rss_date = format_rss_date($item->{date});
    print $fh_feed "  <item>\n";
    print $fh_feed "    <title>$item->{title}</title>\n";
    print $fh_feed "    <link>$item->{link}</link>\n";
    print $fh_feed "    <guid>$item->{link}</guid>\n";
    print $fh_feed "    <description><![CDATA[$item->{desc}]]></description>\n";
    print $fh_feed "    <pubDate>$rss_date</pubDate>\n";
    print $fh_feed "  </item>\n";
}

print $fh_feed "</channel>\n";
print $fh_feed "</rss>\n";
close($fh_feed);

################################################################################
# 🛠️ Helper Functions

sub get_array_from_file{
    my ($filename) = @_;
    my @lines = ();
    open(my $fh, "<:utf8", $filename) or die "Cannot open $filename";
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

# HTML 본문에서 텍스트를 추출하고 무해한 문자열로 클리닝하여 SEO 설명으로 변환
sub clean_html_for_meta {
    my ($html) = @_;
    # 태그 제거
    $html =~ s/<[^>]*>//g;
    # 연속된 줄바꿈, 탭, 공백을 단일 공백으로 압축
    $html =~ s/\s+/ /g;
    $html =~ s/^\s+//;
    $html =~ s/\s+$//;
    # 따옴표 치환 (HTML 깨짐 방지)
    $html =~ s/"/&quot;/g;
    $html =~ s/'/&#39;/g;
    # 150글자 자르기
    if (length($html) > 150) {
        $html = substr($html, 0, 147) . "...";
    }
    return $html;
}

# DD/MM/YYYY 포맷 날짜를 RFC 822 (RSS 표준) 포맷으로 변환
sub format_rss_date {
    my ($date_str) = @_;
    # DD/MM/YYYY 형태가 아닐 경우 원본 반환
    return $date_str unless $date_str =~ m|^(\d{2})\/(\d{2})\/(\d{4})$|;
    
    my ($day, $month_num, $year) = ($1, $2, $3);
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $month_idx = int($month_num) - 1;
    # 인덱스 초과 에러 방지
    $month_idx = 0 if $month_idx < 0 || $month_idx > 11;
    my $month_name = $months[$month_idx];
    
    # 요일은 생략하거나 고정값으로 설정 가능, 여기서는 표준 시간대 정보(+0900)와 함께 RFC 822 포맷으로 결합
    # 예: "19 Jul 2026 00:00:00 +0900"
    return sprintf "%02d %s %d 00:00:00 +0900", $day, $month_name, $year;
}
