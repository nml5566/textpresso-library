#!/usr/bin/perl -w

use strict;
use WWW::Mechanize;

sub GetEcoliWikiEdits {
	my $pmid = shift;
	my $mech = WWW::Mechanize->new(agent => 'Mozilla/5.0', timeout => 30, cookie_jar=> {}, requests_redirectable => [], quiet => [1],); # instantiates a new user agent
	my $url = "http://ecoliwiki.net/rest/is_edited.php?page=PMID:$pmid";
	my $request = $mech->get($url);
	my $page = $mech->content;
	$page =~ s/.*<total>(\d+)<\/total>.*/$1/s;
}

print GetEcoliWikiEdits("2121722");
