package TextpressoDisplayTasks;

# Package provide class and methods for
# tasks related to displaying and maintaining
# Webpages
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena,
#     with contributions by Arun Rangarajan.

use strict;
use POSIX;
use TextpressoGeneralGlobals;
use TextpressoDisplayGlobals;
use TextpressoDatabaseGlobals;
use TextpressoDatabaseCategories;
use TextpressoTable;
use WWW::Mechanize;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PrintTop PrintBottom TLRTable SimpleList CreateFlipPageInterface ParseInputFields ParseSearchString CreateTargetInterface CreateQueryDisplay CreateKeywordInterface CreateCategoryInterface CreateLiteratureInterface CreateKeywordSpecInterface CreateSearchScopeInterface CreateSearchModeInterface CreateSortByInterface CreateParameterSettingInterface CreateCommandTextArea CreateCommandExplanations CreateDisplayOptions CreateDispEpp makeentry PrintStopwordWarning PrintTypeTabs PrintGlobalLinkTable gettext getsentences preparesortresults makehighlightterms CreateFilterInterface Filter FilterSearch);

sub PrintTop {
    
    my $query = shift;
    my $myself = shift;
    my $menuflag = shift;
    
    my $location = "";
    foreach my $key (keys % { (HTML_MENU) }) {
	my $aux = (HTML_MENU)->{$key};
	$aux =~ s/\//\\\//;
	if ($myself =~ /$aux/) {
	    $location = $key;
	}
    }
    
    print $query->header(-cookie => [@_]);
    my $javascript = <<JSEND;
    function openlinkwin(NM, X ,Y, ST) {
	Y = Y - 24;
	var prop = "left=" + X + ",top=" + Y;
	prop = prop + ",width=300,height=150,status=no,toolbar=no,menubar=no,scrollbars=no";
	linkWin = window.open("", NM, prop);
	linkWin.document.write("<HTML><head><title>Multiple Links</title></head>");
	linkWin.document.write ("<BODY>");
	var line = "Multiple links for \'" + NM + "\' found; please choose:<p>";
	linkWin.document.write (line);
	linkWin.document.write (ST);
	linkWin.document.write ("</BODY></HTML>");
	linkWin.document.close();
    }
    function closelinkwin() {
	if (!linkWin.closed)
	    linkWin.self.close();
    }

//Cloning Fields
var counter = 0;

function init() {
        document.getElementById('moreFields').onclick = moreFields;
        moreFields();
}

function moreFields() {
        counter++;
        var newFields = document.getElementById('readroot').cloneNode(true);
        newFields.id = '';
        newFields.style.display = 'block';
        var newField = newFields.childNodes;
        for (var i=0;i<newField.length;i++) {
                var theName = newField[i].name
                if (theName)
                        newField[i].name = theName + counter;
        }
        var insertHere = document.getElementById('writeroot');
        insertHere.parentNode.insertBefore(newFields,insertHere);

window.onload = moreFields;
}    

JSEND
    my $css_style = '<!--
.TextField {
padding: 2px;
height: 14px;
border: 1px solid #CCCCCC;
}
-->';

    print $query->start_html(-title => $location,
			     -author => DSP_AUTHOR,
			     -script => [
					{-src => 'http://tetramer.tamu.edu/textpresso/scripts/jquery.idTabs.min.js'},
					{-code => $javascript}],
			     -style => {-code => $css_style},
			     -text => DSP_TXTCOLOR,
			     -link => DSP_LNKCOLOR,
			     -vlink => DSP_LNKCOLOR,
			     -bgcolor => DSP_BGCOLOR);
    
    if ($menuflag) {
	my @menu = keys % { (HTML_MENU) };
	for (my $i = 0; $i < @menu; $i++) {
	    my $link = (HTML_ROOT) . (HTML_MENU)->{$menu[$i]};
	    if ($menu[$i] =~ /^$location$/) {
		my $clr = (DSP_HIGHLIGHT_COLOR)->{menutexton};
		$menu[$i] = "<span style='font-weight:bold;color:#FDC867'>" . $menu[$i] . "</span>"; 
	    } else {
		my $clr = (DSP_HIGHLIGHT_COLOR)->{menutextoff};
		$menu[$i] = "<span style='font-weight:normal;color:white;text-decoration:none;'>" . $menu[$i] . "</span>"; 
	    }
	    $menu[$i] = "<a href='$link' style='text-decoration: none'>" . $menu[$i] . "</a>";
	}  
	my $main_menu = new TextpressoTable;
	$main_menu->init;
	$main_menu->addtablerow(@menu);

        my $wrap = new TextpressoTable;
        $wrap->init;
        $wrap->addtablerow($query->img({ -src => HTML_ROOT . HTML_LOGO,
                                -border => 0}));
        
         my $wrap2 = new TextpressoTable;
        $wrap2->init;
        $wrap2->addtablerow($main_menu->maketable($query,
                                              tablestyle => 'seamless',
                                              width => '50%',
                                              align => 'left',
                                              DSP_HDRBCKGRND => 'black',
                                              DSP_HDRSIZE => 'small'));
       
        
        print $wrap->maketable($query, tablestyle => 'seamless', DSP_HDRBCKGRND => '#2F6798', width => "100%", align => 'left');
        print $wrap2->maketable($query, tablestyle => 'seamless', DSP_HDRBCKGRND => 'black', width => "100%", align => 'left');

    }
    print $query->start_center;
#    print $query->img({ -src => HTML_ROOT . HTML_LOGO,
#			-border => 0});
    print $query->end_center;

    
    return $location;
}

sub PrintBottom {
    
    my $query = shift;
    my $extramessage = shift;
    my $year = (localtime)[5] + 1900;
print $query->start_center;
    print $query->p;
    printf $query->span({-style=>"font-size:x-small;"}, "© Textpresso $year - ", $query->a({-href => 'about_textpresso'}, 
		    $query->span({-style => "background:white;color:#001EC9;font-size:x-small;text-decoration:underline;"}, "About Textpresso")));
    print $query->span({-style=>"font-size:x-small;"}, $extramessage) if ($extramessage ne '');
    print $query->end_html;
print $query->end_center;
}

sub TLRTable { # stands for Top-(Left-Right) Table
    
    my $query = shift;
    my $top = shift;
    my $left = shift;
    my $right = shift;
    my $width = shift;
    my $returnstring = "";
    
    my $auxtb = new TextpressoTable;
    $auxtb->init;
    $auxtb->addtablerow(""); # no header, please
    $auxtb->addtablerow($top);
    $returnstring = $auxtb->maketable($query,
				      tablestyle => 'borderless',
				      width => $width);
    $auxtb->init;
    $auxtb->addtablerow(""); # no header, please
    $auxtb->addtablerow($left, $right);
    $returnstring .= $auxtb->maketable($query,
				      tablestyle => 'borderless',
				      width => $width);
    return $returnstring;
}

sub SimpleList { # made with table
    
    my $query = shift;
    my $returnstring = "";
    
    my $auxtb = new TextpressoTable;
    $auxtb->init;
    foreach (@_) {
	$auxtb->addtablerow($_);
    }
    return $auxtb->maketable($query,
			     tablestyle => 'borderless',
			     DSP_HDRCOLOR => 'black',
			     DSP_HDRSIZE => 'small',
			     width => '100%');		     
}

sub generateweblinks {
    
    my $query = shift;
    my $string = shift;
    my $output = $string;
    my $on = shift;
    my $p_urls = shift;
    my $p_regexps = shift;
    my $p_explanations = shift;
    
    my @urls = @$p_urls; my @regexps = @$p_regexps; my @explanations = @$p_explanations;
    
    if (!$on) {
	return $output;
    }
    
    my %foundterms = ();
    for (my $i=0; $i < @regexps; $i++) {
	my @matches;
	while ($string =~ /($regexps[$i])/g) {
	    push (@matches, $1);
	}
	
	if (@matches) {
	    foreach my $match (@matches) {
		if (!($match eq "")) {
		    $foundterms{$match}{$i} = 1;
		}
	    }
	}
    }
    
    foreach my $term (keys % foundterms) {
	my $target;
	my @nmbs = keys % {$foundterms{$term}};
	if (scalar(@nmbs) < 2) {
	    (my $suburl = $urls[$nmbs[0]]) =~ s/\#\#\#/$term/;
	    my $e = $explanations[$nmbs[0]];
	    $target = $query->a({href=>$suburl, -target=>"_blank",
				 title=>"Link to $e",
				 style=>'text-decoration:none'}, " $term ");
	} else {
	    my $e = "<p>";
	    foreach my $inst (@nmbs) {
		(my $auxurl = $urls[$inst]) =~ s/\#\#\#/$term/;
		$e .= "<a href='" . $auxurl . "' target='_blank'>";
		$e .= $explanations[$inst];
		$e .= "</a><br>";
	    }
	    my $here = rand() . rand();
	    $target = $query->a({href=>"#here", target =>"_self", # anchor 'here' does not exist, so page stays where it is (hopefully).
				 onClick=>"openlinkwin(\"$term\", event.screenX, event.screenY,\"$e\")",
				 style=>'text-decoration:none'}, $term);
	}
	$output =~ s/(^| )$term( |$)/ $target /g;
    }
	
    return $output;
}

sub CreateFlipPageInterface {

    my $query = shift;
    my $prev = shift;
    my $selector = shift;
    my $next = shift;
    my $displaypage = shift;
    my @choices = @_;

    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("");
#    $aux->addtablerow("Goto:");
    my @row = ();
    if ($prev) {
	push @row, $query->submit(-name => 'previouspage', -value => 'Previous')
	    . $query->font(" ");
	
    }
    if ($selector) {
	push @row,$query->font(" ") 
	    . $query->submit(-name => 'gotopage', -value => 'Page') 
	    . $query->textfield(-name =>'page',
				 -default => $displaypage,
				 -size => 5,
				 -values => \@choices
				)
	    . $query->font(" of", scalar @choices)
	    . $query->font(" ");
    }
    if ($next) {
	push @row, $query->font(" ") . 
	    $query->submit(-name => 'nextpage', -value => 'Next');
    }
	
    $aux->addtablerow(@row);
    return $aux->maketable($query, tablestyle => 'borderless', valign => 'middle');
}

sub ParseInputFields {
    
    my $query = shift;
    my $stopwordstring = shift;
    my $tpquery = new TextpressoDatabaseQuery;
    $tpquery->init;
    
    my %literatures = ();
    foreach ($query->param('literature')) {
	$literatures{$_} = 1;
    }

#

    my %targets = ();
    foreach ($query->param('target')) {
	$targets{$_} = 1;
    }
    foreach ($query->param('target1')) {
	$targets{$_} = 1;
    }
    foreach ($query->param('target2')) {
	$targets{$_} = 1;
    }
    foreach ($query->param('target3')) {
	$targets{$_} = 1;
    }
    foreach ($query->param('target4')) {
	$targets{$_} = 1;
    }   
#
    
    for (my $i = 1; $i < 5; $i++) {
	if ($query->param("cat$i") ne HTML_NONE) {
	    my $aux = (DB_CATEGORIES)->{$query->param("cat$i")};
	    if (defined(@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}})) {
		foreach my $child (@{(DB_CATEGORYCHILDREN)->{$query->param("cat$i")}}) {
		    $aux .= "," . (DB_CATEGORIES)->{$child};
		}
	    }
	    $tpquery->addsimple('category', $aux,
				$query->param('sentencerange'), $query->param('exactmatch') || 0,
				$query->param('casesensitive') || 0, \%literatures, \%targets);
	}
    }
    
#

    my $foundstopwords = ParseSearchString($query->param('searchstring'), $tpquery, $stopwordstring, 0, '>',
					   $query->param('sentencerange'), $query->param('exactmatch') || 0,
					   $query->param('casesensitive') || 0, \%literatures, \%targets);

#

    return ($tpquery, $foundstopwords);
}

sub ParseSearchString {

    my $string = shift;
    my $tpquery = shift;
    my $stopwordstring = shift;
    my $num = shift;
    my $comp = shift;
    my $range = shift;
    my $exactmatch = shift;
    my $casesensitive = shift;
    my $pLit = shift;
    my $pTgt = shift;
    my $foundstopwords = "";
    
    my @plusphrases = ();
    while ($string =~ /(\s|^)\"([^\"]+)\"(\s|$)/g) {
	push @plusphrases, $2;
	$string =~ s/\"$2\"//;
    }
    my @minusphrases = ();
    while ($string =~  /(\s|^)\-\"([^\"]+)\"(\s|$)/g) {
	push @minusphrases, $2;
	$string =~ s/\-\"$2\"//;
    }
    my @minuswords = ();
    while ($string =~ /(\s|^)\-(\S+?)(\s|$)/g) {
	push @minuswords, $2;
       $string =~ s/\-$2//;
    }
    my @pluswords = ();
    while ($string =~ /(\s|^)(\S+?)(\s|$)/g) {
	push @pluswords, $2;
	$string =~ s/$2//;
    }
    foreach my $line (@plusphrases) {
	my @entries = split(/\s/, $line);
	my $aux = shift(@entries);
	if ($stopwordstring =~ /\s$aux\s/) {
	    $foundstopwords .= $aux . " ";
	} else {
	    $tpquery->addspecific('&&', 'keyword', $aux, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	}
	while (my $word = shift(@entries)) {
	    if ($stopwordstring =~ /\s$word\s/) {
		$foundstopwords .= $word . " ";
	    } else {
		$tpquery->addspecific('++', 'keyword', $word, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	    }
	}
    }
    foreach my $word (@pluswords) {
	if ($stopwordstring =~ /\s$word\s/) {
	    $foundstopwords .= $word . " ";
	} else {
	    $tpquery->addspecific('&&', 'keyword', $word, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	}
    }
    foreach my $line (@minusphrases) {
	my @entries = split(/\s/, $line);
	my $aux = shift(@entries);
	if ($stopwordstring =~ /\s$aux\s/) {
	    $foundstopwords .= $aux . " ";
	} else {
	    $tpquery->addspecific('!!', 'keyword', $aux, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	}
	while (my $word = shift(@entries)) {
	    if ($stopwordstring =~ /\s$word\s/) {
		$foundstopwords .= $word . " ";
	    } else {
		$tpquery->addspecific('--', 'keyword', $word, $num,  $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	    }
	}
    }
    foreach my $word (@minuswords) {
	if ($stopwordstring =~ /\s$word\s/) {
	    $foundstopwords .= $word . " ";
	} else {
	    $tpquery->addspecific('!!', 'keyword', $word, $num, $comp, $range, $exactmatch, $casesensitive, $pLit, $pTgt);
	}
    }
    return $foundstopwords;	   
}

sub CreateQueryDisplay {

    my $query = shift;
    my $tpquery = shift;

    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Query");
    $aux->addtablerow("Condition", 
		      "Concatenation", 
		      "Type", 
		      "Data Entry", 
		      "Comparison",
		      "Numerics",
		      "Sentence Range",
		      "Exact Match?",
		      "Case Sensitive?",
		      "Literatures",
		      "Fields");
    for (my $i = 0; $i < $tpquery->numberofconditions; $i++) {
	my $matchanswer = ($tpquery->exactmatch($i) == 1) ? 'yes' : 'no';
	my $caseanswer = ($tpquery->casesensitive($i) == 1) ? 'yes' : 'no';
	$aux->addtablerow($i,
			  $tpquery->boolean($i),
			  $tpquery->type($i),
			  $tpquery->data($i),
			  $tpquery->comparison($i),
			  $tpquery->occurrence($i),
			  $tpquery->range($i),
			  ($tpquery->exactmatch($i)) ? 'yes' : 'no',
			  ($tpquery->casesensitive($i)) ? 'yes' : 'no',
			  join(", ", $tpquery->literatures($i)),
			  join(", ", $tpquery->targets($i)));
    }
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground', 
			   DSP_HDRBCKGRND => (DSP_HIGHLIGHT_COLOR)->{bgwhite},
			   DSP_HDRCOLOR => 'black');

}

sub CreateDispEpp {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    my @sortchoice = qw(5 10 20 50);
    $aux->addtablerow("Show ". $query->popup_menu(-name => 'disp_epp',
					 -onChange => q/document.getElementById('main_form').submit()/,
					 -values => [@sortchoice],
					 -default => '5',
		      ));

    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', 
			   width => '100%');
}


sub CreateKeywordInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("for " . $query->textfield(-name => 'searchstring', -size => 50, -maxlength => 255),
$query->submit(-name => 'search', -value => 'Go')
			. $query->font("&nbsp;")
			. $query->reset('Clear'));
#    $aux->addtablerow("Separate multiple, <em>required</em> keywords by white spaces (Boolean \'and\').");
#    $aux->addtablerow("Separate multiple, <em>alternative</em> keywords by a comma with no white spaces (Boolean \'or\').");
#    $aux->addtablerow("Enter phrases in double quotes, and put a '-' sign in front of words which are to be excluded.");
    return $aux->maketable($query, 
			   tablestyle => 'borderless', DSP_BGCOLOR => '#CCCCCC',# DSP_HDRCOLOR => '#FDC867',
			   DSP_HDRSIZE => 'small', align => 'left', 
			   width => '100%');
}

sub FilterSearch {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow($query->span({-style => 'font-weight:normal;color:white;'}, "title of article:"),
			$query->textfield(-name => 'titlestring', -size => 50, -maxlength => 255));
    $aux->addtablerow($query->span({-style => 'font-weight:normal;color:white;'}, "author(s):"), 
			$query->textfield(-name => 'authorstring', -size => 50, -maxlength => 255));
    $aux->addtablerow($query->span({-style => 'font-weight:normal;color:white;'}, "publication date:"),
			$query->textfield(-name => 'yearstring', -size => 50, -maxlength => 255));
    $aux->addtablerow($query->span({-style => 'font-weight:normal;color:white;'}, "type (e.g. review):"),
			$query->textfield(-name => 'typestring', -size => 50, -maxlength => 255));
    $aux->addtablerow($query->span({-style => 'font-weight:normal;color:white;'}, "journal name:"),
			$query->textfield(-name => 'journalstring', -size => 50, -maxlength => 255));
    $aux->addtablerow($query->span({-style => 'font-weight:normal;color:white;'}, "mesh headings:"),
			$query->textfield(-name => 'meshstring', -size => 50, -maxlength => 255));
    return $aux->maketable($query, 
			   tablestyle => 'borderless', DSP_BGCOLOR => '#2F6798', DSP_HDRCOLOR => '#FDC867',
			   DSP_HDRSIZE => 'small', align => 'right', 
			   width => '100%');
}
sub CreateFilterInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Narrow your search results with filter:");
    $aux->addtablerow($query->textfield(-name => 'filterstring', -size => 50, -maxlength => 255) . " " .
		      $query->submit(-name => 'filter', -value => 'Filter!'));
    $aux->addtablerow("Put a '+' sign in front of words which have to be included,\
                       a '-' sign in front of words which have to be excluded. \
                       Enter the field of the word, <em>viz</em> author, title, \
                       year, journal, abstract, accession, type or sentence \ 
                       in square brackets. Enter phrases in double quotes.");
    $aux->addtablerow("For example, to find all the papers in the search result \
                       that have <em>Jack</em> as author,
	               but not <em>John</em>, enter \+Jack\-John\[author\]\. \
                       To exclude all papers that have the phrase <em>double mutant</em> \
                       in title, enter \-\"double mutant\"\[title\].
	               You can combine several filters and enter something like 
	               +Kim[author] \-\"double mutant\"\[title\] +15943900[accession] +2005[year] -review\[type\]. ");
    $aux->addtablerow("Click on Filter! button to activate the filter.");
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small',
			   width => '100%');
}

sub CreateCategoryInterface {

    my $query = shift;
   # my $aux = new TextpressoTable;
   # $aux->init;
    use TextpressoDatabaseCategories;
    my $none = HTML_NONE;
    my @categories = sort ($none, keys %{(DB_CATEGORIES)});
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Categories:");
    $aux->addtablerow($query->popup_menu(-name => 'cat1',
					   -values => [sort @categories],
					   -default => $none));
    $aux->addtablerow($query->popup_menu(-name => 'cat2',
					   -values => [sort @categories],
					   -default => $none));
    $aux->addtablerow($query->popup_menu(-name => 'cat3',
					   -values => [sort @categories],
					   -default => $none));
    $aux->addtablerow($query->popup_menu(-name => 'cat4',
					   -values => [sort @categories],
					   -default => $none));
   # $aux->addtablerow($miniT->maketable($query, tablestyle => 'borderless', valign => 'middle'));
    return $aux->maketable($query, 
			   tablestyle => 'borderless', 
			   DSP_HDRBCKGRND => '#2F6798', DSP_HDRCOLOR => '#FDC867', DSP_BGCOLOR => '#2F6798', align => 'left',
			   DSP_HDRSIZE => 'small',
			   width => '100%');
    
}

sub CreateLiteratureInterface {

    my $query = shift;
    my $error = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Literature:");
    $aux->addtablerow($query->checkbox_group(-name => 'literature',
					     -values => [sort keys %{(DB_LITERATURE)}],
					     -defaults => [@{(DB_LITERATURE_DEFAULTS)}],
					     -cols => 1));
    return $aux->maketable($query,
			   tablestyle => 'borderless-headerbackground', 
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => $error || '#FDC867',
			   DSP_HDRBCKGRND => '#2F6798', DSP_HDRCOLOR => '#FDC867', DSP_BGCOLOR => '#2F6798', width => "100%", align => 'left',
			   width => '100%');
}

#sub CreateTargetInterface {
#
#    my $query = shift;
#    my $aux = new TextpressoTable;
#    $aux->init;
#    $aux->addtablerow("Fields");
#    $aux->addtablerow($query->checkbox_group(-name => 'target',
#					     -values => [sort keys %{(DB_SEARCH_TARGETS)}],
#					     -defaults => [@{(DB_SEARCH_TARGETS_DEFAULTS)}],
#					     -rows => 2));
#    return $aux->maketable($query,
#			   tablestyle => 'borderless-headerbackground',
#			   DSP_HDRSIZE => 'small', 
#			   width => '100%');
#    
#}

sub CreateTargetInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
my @targets = sort (keys %{(DB_SEARCH_TARGETS)});
    $aux->init;
   # $aux->addtablerow($query->popup_menu(-name => 'target', -values => [sort @targets], -default => $targets[2],));
$aux->addtableelement('Search');
    $aux->addtablerow($query->popup_menu(-name => 'target', -values => [sort @targets], -default => $targets[2],) . 
			$query->a({href=>'Javascript:moreFields()', 
				-style => 'font-weight:normal;color:#2F6798;text-decoration:none;'}, ' +') .
			$query->span( {-id => 'writeroot'} ), 
			);

    return $aux->maketable($query,
			   tablestyle => 'borderless', 
			   DSP_HDRSIZE => 'small', DSP_BGCOLOR => '#CCCCCC',
			   width => '100%');
    
}

sub CreateKeywordSpecInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
#    $aux->addtablerow("Keyword Specifications:");
    $aux->addtablerow($query->checkbox(-name => 'exactmatch', 
				       -label => 'Exact match'));
    $aux->addtablerow($query->checkbox(-name => 'casesensitive',
				       -label => 'Case sensitive'));
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', 
			   DSP_HDRBCKGRND => '#CCCCCC', DSP_HDRCOLOR => 'black', DSP_BGCOLOR => '#CCCCCC', align => 'left',
			   width => '100%');
}

sub CreateSearchScopeInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Search Scope:");
    $aux->addtablerow($query->popup_menu(-name => 'sentencerange',
					 -values => [sort keys %{(DB_SEARCH_RANGES)}],
					 -default => DB_SEARCH_RANGES_DEFAULT));
    return $aux->maketable($query, 
			   tablestyle => 'borderless',
			   DSP_HDRSIZE => 'small', 
			   DSP_HDRBCKGRND => '#2F6798', DSP_HDRCOLOR => '#FDC867', DSP_BGCOLOR => '#2F6798', align => 'left',
			   width => '100%');
}


sub CreateSearchModeInterface {

    my $query = shift;
    my $error = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("Search Mode:");
    $aux->addtablerow($query->popup_menu(-name => 'mode',
					 -values => [sort @{(DB_SEARCH_MODE)}],
					 -default => DB_SEARCH_MODE_DEFAULT));    
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground', 
			   DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => $error || '#2F6798',
			   DSP_HDRCOLOR => '#FDC867', DSP_BGCOLOR => '#2F6798', width => "100%", align => 'left',
			   width => '100%');
}

sub CreateSortByInterface {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    my @sortchoice = sort ("Sort By", "score (hits)", keys % {(DB_DISPLAY_FIELDS)});
    $aux->addtablerow($query->popup_menu(-name => 'sort',
					 -onChange => q/document.getElementById('main_form').submit()/,
					 -values => [@sortchoice],
					 -default => 'Sort By',
		      ));
					 #-default => 'score (hits)',
    return $aux->maketable($query, 
			   tablestyle => 'borderless-headerbackground',
			   DSP_HDRSIZE => 'small', 
			   );
}

sub CreateParameterSettingInterface {

    my $query = shift;
    my $paramtable = new TextpressoTable;
    $paramtable->init;
    $paramtable->addtablerow("Parameter Settings");
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Literature(s): ") .
			     $query->span({-style => 'font-weight:normal;'}, join(", " , $query->param('literature'))));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Field(s): ") .
			     $query->span({-style => 'font-weigt:normal;'}, join(", " , $query->param('target'), 
											$query->param('target1'), 
											$query->param('target2'),
											$query->param('target3'),
											$query->param('target4'),
										)));
    my $answer = ($query->param('exactmatch')) ? 'Yes' : 'No';
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Exact match? ") .
			     $query->span({-style => 'font-weigt:normal;'}, $answer));
    $answer = ($query->param('casesensitive')) ? 'Yes' : 'No';
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Case sensitive? ") .
			     $query->span({-style => 'font-weigt:normal;'}, $answer));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Sentence Scope: ") .
			     $query->span({-style => 'font-weigt:normal;'}, $query->param('sentencerange')));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Search Mode: ") .
			     $query->span({-style => 'font-weigt:normal;'}, $query->param('mode')));
    $paramtable->addtablerow($query->span({-style => 'font-weight:bold;'}, "Sorted by: ") .
			     $query->span({-style => 'font-weigt:normal;'}, $query->param('sort')));
    
    return $paramtable->maketable($query, tablestyle => 'borderless-headerbackground', 
				  DSP_HDRSIZE => 'small', DSP_HDRBCKGRND => '#D5DDF1', width => "100%");
}

sub CreateCommandTextArea {

    my $query = shift;
    my $title = shift;
    my $line1 = shift;
    my $line2 = shift;
    my $commandtable = new TextpressoTable;
    $commandtable->init;
    $commandtable->addtablerow("Commands");
    $commandtable->addtablerow($query->span({-style => 'font-style:normal;'}, $line1) .
			       $query->span({-style => 'font-style:normal;'}, $line2));
    $commandtable->addtablerow($query->textarea(-name => 'commands',
						-rows => '8',
						-columns => '50'));
    $commandtable->addtablerow($query->submit(-name => 'submit',
					      -value => 'Submit!'));
    
    return $commandtable->maketable($query, tablestyle => 'borderless-headerbackground',  
				    DSP_HDRSIZE => 'small', width => "100%");
}

sub CreateCommandExplanations {
    
    my $query = shift;
    my $history = shift;
    my $explanation = new TextpressoTable;
    $explanation->init;
    $explanation->addtablerow("Explanations");
    $explanation->addtablerow($query->span({-style => 'font-weight:bold;'}, "Available Commands:"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "set ") .
			      $query->span({-style => 'font-style:normal;'}, "parameter-name ") .
			      $query->span({-style => 'font-style:italic;'}, "= ") .
			      $query->span({-style => 'font-style:normal;'}, "value-1, value-2, ... \'"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "clear ") .
			      $query->span({-style => 'font-style:normal;'}, "(parameter-name | ") .
			      $query->span({-style => 'font-style:italic;'}, "all") .
			      $query->span({-style => 'font-style:normal;'}, ")"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "find ") .
			      $query->span({-style => 'font-style:normal;'}, "(") .
			      $query->span({-style => 'font-style:italic;'}, "keyword ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "category") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "attribute") .
			      $query->span({-style => 'font-style:normal;'}, ") (keyword | ") .
			      $query->span({-style => 'font-style:italic;'}, "\"") .
			      $query->span({-style => 'font-style:normal;'}, "phrase") .
			      $query->span({-style => 'font-style:italic;'}, "\"") .
			      $query->span({-style => 'font-style:normal;'}, " | category | category") .
			      $query->span({-style => 'font-style:italic;'}, ":") .
			      $query->span({-style => 'font-style:normal;'}, "attribute") .
			      $query->span({-style => 'font-style:italic;'}, ":") .
			      $query->span({-style => 'font-style:normal;'}, "value) (") .
			      $query->span({-style => 'font-style:italic;'}, "< ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "== ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, ">") .
			      $query->span({-style => 'font-style:normal;'}, ") number ") .
			      $query->span({-style => 'font-style:italic;'}, "->") .
			      $query->span({-style => 'font-style:normal;'}, " variable-name"));
    $explanation->addtablerow($query->span({-style => 'font-style:normal;'}, "(") .
			      $query->span({-style => 'font-style:italic;'}, "and ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "or ") .
			      $query->span({-style => 'font-style:normal;'}, "| ") .
			      $query->span({-style => 'font-style:italic;'}, "not") .
			      $query->span({-style => 'font-style:normal;'}, ") ") .
			      $query->span({-style => 'font-style:normal;'}, "variable-name-1 variable-name-2 ") .
			      $query->span({-style => 'font-style:italic;'}, "->") .
			      $query->span({-style => 'font-style:normal;'}, " variable-name-3"));
    $explanation->addtablerow($query->span({-style => 'font-style:italic;'}, "display ") .
			      $query->span({-style => 'font-style:normal;'}, "variable-name"));
    if ($history ne "") {
	$explanation->addtablerow("");
	$explanation->addtablerow($query->span({-style => 'font-weight:bold;'}, "Last Command(s):"));
	$explanation->addtablerow($query->span({-style => 'font-style:normal;'}, $history));
    }
    
    return $explanation->maketable($query, tablestyle => 'borderless-headerbackground',  
				   DSP_HDRSIZE => 'small', width => "100%", DSP_HDRBCKGRND => 'seagreen');

}

sub CreateDisplayOptions {

    my $query = shift;
    my $aux = new TextpressoTable;
    $aux->init;
    $aux->addtablerow("");
    $aux->addtablerow($query->span({-style=>"font-size:small;"}, "Display options:"));

    my $none = HTML_NONE;
    my $on = HTML_ON;
    my $off = HTML_OFF;

    my @row = ();
    my $count = 0;
    my $selfurl = $query->self_url;
    my $oncolor = (DSP_HIGHLIGHT_COLOR)->{oncolor};
    my $offcolor = (DSP_HIGHLIGHT_COLOR)->{offcolor};
    foreach my $opt (keys % {(DB_DISPLAY_FIELDS)}, 'supplementals', 'textlinks', 'searchterm-highlighting') {
	my $entry = $opt . ': ';
	if (!defined($query->param("disp_$opt"))) {
	    $query->param(-name => "disp_$opt", -value => $on);
	    $query->param(-name => "disp_mesh", -value => $off);
	}
	(my $actualurl = $selfurl) =~ s/disp_$opt=$on//g; 
	$actualurl =~ s/disp_$opt=$off//; 
	if ($query->param("disp_$opt") eq $on) {
	    $entry .= $query->start_b;
	    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$on"}, $query->span({-style=>"font-size:small;color:$oncolor"}, $on));
	    $entry .= $query->end_b;
	    $entry .= $query->span({-style=>"font-size:small;"}, " | ");
	    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$off"}, $query->span({-style=>"font-size:small;"}, $off));
	} else {
	    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$on"}, $query->span({-style=>"font-size:small;"}, $on));
	    $entry .= $query->span({-style=>"font-size:small;"}, " | ");
	    $entry .= $query->start_b;
	    $entry .= $query->a({-href => "$actualurl\;disp_$opt=$off"}, $query->span({-style=>"font-size:small;color:$offcolor"}, $off));
	    $entry .= $query->end_b;
	}
	push @row, $entry;
	if ((++$count % 5) == 0) {
	    $aux->addtablerow(@row);
	    @row = ();
	}
    }
    my $entry = "matching sentences: ";
    if (!defined ($query->param("disp_matches"))) {
	$query->param(-name => "disp_matches", -value => 1);
    }
    (my $actualurl = $selfurl) =~ s/disp_matches=($none|1|5|10)//g;
    foreach my $opt ("$none", 1, 5, 10) {
	my $str = "";
	if ($query->param("disp_matches") == $opt) {
	    $entry .= $query->start_b;
	    $str = $query->span({-style=>"font-size:small;color:$oncolor"}, $opt);
	} else {
	    $str = $opt;
	}
	$entry .= $query->a({-href => "$actualurl\;disp_matches=$opt"}, $query->span({-style=>"font-size:small;"}, $str));
	$entry .= $query->span({-style=>"font-size:small;"}, " ");
	if ($query->param("disp_matches") == $opt) {
	    $entry .= $query->end_b;
	}
    }
    push @row, $entry;
    if ((++$count % 5) == 0) {
	$aux->addtablerow(@row);
	@row = ();
    }
    $entry = "entries/page: ";
    if (!defined($query->param("disp_epp"))) {
	$query->param(-name => "disp_epp", -value => 5);
    }
    ($actualurl = $selfurl) =~ s/disp_epp=(5|10|20|50)//g;
    foreach my $opt (5, 10, 20, 50) {
	my $str = "";
	if ($query->param("disp_epp") == $opt) {
	    $entry .= $query->start_b;
	    $str = $query->span({-style=>"font-size:small;color:$oncolor"}, $opt);
	} else {
	    $str = $opt;
	}
	$entry .= $query->a({-href => "$actualurl\;disp_epp=$opt"}, $query->span({-style=>"font-size:small;"}, $str));
	$entry .= $query->span({-style=>"font-size:small;"}, " ");
	if ($query->param("disp_epp") == $opt) {
	    $entry .= $query->end_b;
	}
    }
    #push @row, $entry;

    $aux->addtablerow(@row);
    return $aux->maketable($query, tablestyle => 'borderless', valign => 'middle');
}

sub makeentry {
    
    my $query = shift;
    my $table = shift;
    my $ltk = shift;
    my $pSEN = shift;
    my $pResults = shift;
    #############################
    my $p_urls = shift;
    my $p_regexps = shift;
    my $p_explanations = shift;
    #############################
    my $var = shift; 

    (my $lit, my $tgt, my $key) = split(/\ -\ /, $ltk);
    
    my $none = HTML_NONE;
    my $on = HTML_ON;
    my $leftcontent = "";

    if ($query->param("disp_title") eq $on) {
	my $pmid = $key;
	my $title = highlighttext(generateweblinks($query, gettext($lit, 'title', $key), 
					   ($query->param("disp_textlinks") eq $on), $p_urls, $p_regexps, $p_explanations), 
			  (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
			  $var);
        if ($ENV{'REMOTE_ADDR'} =~ /^165\.91/) {
        	if (-e "/usr/local/textpresso/ecoli/Data/includes/pdf/$pmid.pdf") {
#			$leftcontent =  $query->span({-style => "font-weight:bold;"}, "Title: "); 
			$leftcontent .= $query->a({-href => "showpdf?filename=$pmid.pdf",
						       -target => "_blank"},
						      $query->span({-style => "font-weight:normal;font-size:medium;background:white;color:#001EC9;text-decoration:underline;"}, "$title"));
		} else { $leftcontent =  $query->span({-style => "font-size:medium;text-decoration:underline"},$title); 
	}

	} else {
	#	$leftcontent =  $title; #$query->span({-style => "font-weight:bold;"}, "Title: ") . $title; 
		$leftcontent =  $query->span({-style => "font-size:medium;text-decoration:underline;"},$title);
	}
    }
    $table->addtablerow($leftcontent);
    
    if ($query->param("disp_author") eq $on) {
	#$leftcontent =  $query->span({-style => "font-weight:bold;"}, "Author: ") . gettext($lit, 'author', $key);
	$leftcontent = $query->span({-style => "font-size:medium;"}, gettext($lit, 'author', $key));
	$table->addtablerow($leftcontent);
    }
    $leftcontent = "";
    if ($query->param("disp_journal") eq $on) {
	#$leftcontent .= $query->span({-style => "font-weight:bold;"}, " Journal: ") . gettext($lit, 'journal', $key);
	$leftcontent .= $query->span({-style => "font-size:small;"}, gettext($lit, 'journal', $key));
    }
    if ($query->param("disp_year") eq $on) {
#	$leftcontent .= $query->span({-style => "font-weight:bold;"}, " Year: ") . gettext($lit, 'year', $key);
	$leftcontent .= $query->span({-style => "font-size:small;"}, " " . gettext($lit, 'year', $key));
    }
    if ($query->param("disp_citation") eq $on) {
	#$leftcontent .= $query->span({-style => "font-weight:bold;"}, " Citation: ") . gettext($lit, 'citation', $key);
	$leftcontent .= $query->span({-style => "font-size:small;"}, gettext($lit, 'citation', $key));
    }
    my $aux = gettext($lit, 'type', $key);
    if ($query->param("disp_type") eq $on) {
	$leftcontent .= $query->span({-style => "font-weight:bold;"}, " Type: ") . $aux;
    }
    if ($aux =~ /(meeting|gazette)/i) {
	my $wrnclr =(DSP_HIGHLIGHT_COLOR)->{warning}; 
	$leftcontent .= $query->span({-style => "font-weight:bold;color:$wrnclr;"}, " Unpublished information; cite only with author permission.");
    }
#    if ($leftcontent ne "") {
#	$table->addtablerow($leftcontent);
#    }
 #   $leftcontent = $query->span({-style => "font-weight:bold;"}, " Literature: ") . $lit;
 #   $leftcontent .= $query->span({-style => "font-weight:bold;"}, " Field: ") . $tgt;
 #   $leftcontent .= $query->span({-style => "font-weight:bold;"}, " Doc ID: ") . $key;
    $table->addtablerow($leftcontent);
    $leftcontent = "";
#    if ($query->param("disp_mesh") eq $on) {
#	$leftcontent .= $query->span({-style => "font-weight:bold;"}, " MESH Headings: ") . gettext($lit, 'mesh', $key);
#    }
    $table->addtablerow($leftcontent);
    $leftcontent = "";
    if ($query->param("disp_abstract") eq $on) {
#	$leftcontent .= $query->span({-style => "font-weight:bold;"}, " Abstract: ") . 
#	    highlighttext(generateweblinks($query, gettext($lit, 'abstract', $key), 
#					   ($query->param("disp_textlinks") eq $on), $p_urls, $p_regexps, $p_explanations),
#			  (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
#			  $var);
	$leftcontent .= $query->span({-style => "font-size:medium;"},  
	    highlighttext(generateweblinks($query, gettext($lit, 'abstract', $key), 
					   ($query->param("disp_textlinks") eq $on), $p_urls, $p_regexps, $p_explanations),
			  (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
			  $var));

    }
    $table->addtablerow($leftcontent);
    $leftcontent = "";
    if ($query->param("disp_accession") eq $on) {
#	$leftcontent .= $query->span({-style => "font-weight:bold;"}, " Accession (PMID): ") . gettext($lit, 'accession', $key);
	$leftcontent .= $query->span({-style => "font-size:small;color:#696969;"}, "PMID: " . gettext($lit, 'accession', $key));
    }
    if ($leftcontent ne "") {
	$table->addtablerow($leftcontent);
    }
    $leftcontent = "";
    if ($query->param("disp_matches") ne $none) {
	my $range = $query->param("disp_matches") - 1;
	$leftcontent .= $query->span({-style => "font-weight:bold;"}, " Matching Sentences: ");
	$leftcontent .= $query->br;
	my @text = getsentences($lit, $tgt, $key);	
	############################################################################
	# Find sentences that are very long or look like tables and figures - arun.
	my @hide;
	for (my $i=0; $i < @text; $i++) {
	    $hide[$i] = 0;
	}

	for (my $i=0; $i<@text; $i++) {
	    my @s = split /\s+/,$text[$i];
	    my $size_of_s = @s;
	    
	    # Very long sentence
	    if ($size_of_s > 400) {
		$hide[$i] = 1;
	    }
	    
	    # Table or figure
	    if ($text[$i] =~ /\d+\s+\d+\s+\d+\s+\d+/ && ( ($text[$i] =~ /table/i) || ($text[$i] =~ /figure/i)) ) {
		$hide[$i] = 1;
	    }
	    
	    # Repeat patterns
	    if ($text[$i] ne "") {
		foreach my $w (@s) {
		    if ($w =~ /\w+/) {
			my $rep = $w." ".$w." ".$w." ".$w;
			if ($text[$i] =~ /"\Q$rep\E"/i) {	
			    $hide[$i] = 1;
			    last;
			}

		    }
		}
	    }
	}
	my %subscore = ();
	foreach my $clstr (@$pSEN) {
	    my $sc = $$pResults{$lit}{$key}{$tgt}{$clstr};
	    #if ($sc < 30) { # Very high score may be table or figure
		push @{$subscore{$sc}}, $clstr;
	    #}
	}
	############################################################################

	foreach my $sc (sort descending keys % subscore) {
	    foreach my $clstr (sort sentencewise @{$subscore{$sc}}) {
		$clstr =~ s/s//g;
		my $actual = $clstr - 1;
		my $lower = ($actual - $range < 0) ? 0 : $actual - $range;
		my $upper = ($actual + $range > scalar(@text)) ? scalar(@text) : $actual + $range;
		my $new_window = 0;
		for (my $i = $lower; $i <= $upper; $i++) {
		    $new_window = 1 if ($hide[$i] == 1);
		}
		if ($new_window == 0) {
		    if ($text[$lower] ne "") {	
			$leftcontent .= $query->span({-style => "font-weight:bold;"}, 
						     " [ Sen. " . $clstr . ", subscore: " . sprintf("%4.2f", $sc) . " ]: ");
			for (my $i = $lower; $i < $actual; $i++) {
			    $leftcontent .= highlighttext(generateweblinks($query, $text[$i], ($query->param("disp_textlinks") eq $on), 
									   $p_urls, $p_regexps, $p_explanations),
							  (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
							  $var);
			}
			my $emphasis = ($range > 0) ? "font-weight:bold;" : "font-weight:normal;";
			
			$leftcontent .= $query->span({-style => $emphasis}, 
						     highlighttext(generateweblinks($query, $text[$actual], 
										    ($query->param("disp_textlinks") eq $on), 
										    $p_urls, $p_regexps, $p_explanations),
								   (DSP_HIGHLIGHT_COLOR)->{texthighlight},
								   $var));
			for (my $i = $actual + 1; $i <= $upper; $i++) {
			    $leftcontent .= highlighttext(generateweblinks($query, $text[$i], ($query->param("disp_textlinks") eq $on), 
									   $p_urls, $p_regexps, $p_explanations),
							  (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
							  $var);
			}
			$leftcontent .= $query->br;
		    }
		} else {
		    my $sen_file_name;
		    do { $sen_file_name = tmpnam() } until (!-e DB_TMP . '/' . $sen_file_name);
		    my $file_name = $sen_file_name;
		    $sen_file_name = DB_TMP . '/' . $sen_file_name;
#		    system ("chmod 755 $sen_file_name");
		    open (OUT, ">$sen_file_name") || die ("Could not open $sen_file_name for writing.");
		    my $highlighted_sen = "";
		    $leftcontent .= $query->span({-style => "font-weight:bold;"}, 
						 " [ Sen. " . $clstr . ", subscore: " . sprintf("%4.2f", $sc) . " ]: ");
		    for (my $i = $lower; $i < $actual; $i++) {
			$highlighted_sen = highlighttext(generateweblinks($query, $text[$i], ($query->param("disp_textlinks") eq $on), 
									  $p_urls, $p_regexps, $p_explanations),
							 (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
							 $var);
			print OUT "$highlighted_sen\n";
		    }
		    my $emphasis = ($range > 0) ? "font-weight:bold;" : "font-weight:normal;";
		    $highlighted_sen = $query->span({-style => $emphasis}, 
						    highlighttext(generateweblinks($query, $text[$actual], 
										   ($query->param("disp_textlinks") eq $on), 
										   $p_urls, $p_regexps, $p_explanations),
								  (DSP_HIGHLIGHT_COLOR)->{texthighlight},
								  $var));
		    print OUT "$highlighted_sen\n";
		    for (my $i = $actual + 1; $i <= $upper; $i++) {
			$highlighted_sen = highlighttext(generateweblinks($query, $text[$i], ($query->param("disp_textlinks") eq $on), 
									  $p_urls, $p_regexps, $p_explanations),
							 (DSP_HIGHLIGHT_COLOR)->{texthighlight}, 
							 $var);
			print OUT "$highlighted_sen\n";
		    }
		    close(OUT);
		    $leftcontent .= $query->a({-href => "showsentence?filename=$file_name", -target => '_blank',
					       -style => 'text-decoration:none'},
					      $query->font({-color => 'darkgreen'},
							   " [Sentence\(s\) appears to be scrambled. Click to see (opens new window)] "));
		    $leftcontent .= $query->br;
		}
	    }
	}
    }
    if ($leftcontent ne "") {
	$table->addtablerow($leftcontent);
    }

    $leftcontent ="";
    if ($query->param("disp_supplementals") eq $on) {
#	$leftcontent .= $query->span({-style => "font-weight:bold;"}, "Additional links/files: ");
	my $pmid = gettext($lit, 'accession', $key);
	chomp ($pmid);
	$pmid =~ s/\s//g;
	if ($pmid =~ /pmid\s*(\d+)/i) {
	    $pmid = $1;
	}
	if ($pmid =~ /^\d+$/) {
	    $leftcontent .= " ";
	    my $clr = (DSP_HIGHLIGHT_COLOR)->{3};
	    $leftcontent .= $query->a({-href => "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?dbfrom=pubmed&id=$pmid&retmode=ref&cmd=prlinks",
				       -target => "_blank"},
				      $query->span({-style => "background:white;color:$clr;text-decoration:underline;"}, "Pubmed link"));
	    $leftcontent .= " ";
	    my $clr = (DSP_HIGHLIGHT_COLOR)->{2};
	    $leftcontent .= $query->a({-href => "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Display&db=pubmed&dopt=pubmed_pubmed&from_uid=$pmid",
				       -target => "_blank"},
				      $query->span({-style => "background:white;color:$clr;text-decoration:underline;"}, "Related articles"));
	    $leftcontent .= " ";
	    my $clr = (DSP_HIGHLIGHT_COLOR)->{7};
	    $leftcontent .= $query->a({-href => "exportendnote?mode=singleentry&lit=$lit&id=$key"}, 
				  $query->span({-style => "background:white;color:$clr;text-decoration:underline;"},"Endnote reference"));
	    $leftcontent .= " ";
	    my $clr = (DSP_HIGHLIGHT_COLOR)->{5};
	    $leftcontent .= $query->a({-href => "http://ecoliwiki.net/PMID:$key", 
				       -target => "_blank"},
				  $query->span({-style => "background:white;color:$clr;text-decoration:underline;"},"EcoliWiki ", GetEcoliWikiEdits($key)));
	}
    }
    if ($leftcontent ne "") {
	$table->addtablerow($leftcontent);
    }

    return 1;
    
}

sub GetEcoliWikiEdits {
	my $pmid = shift;
	my $mech = WWW::Mechanize->new(agent => 'Mozilla/5.0', timeout => 30, cookie_jar=> {}, requests_redirectable => [], quiet => [1],); # instantiates a new user agent
	my $url = "http://ecoliwiki.net/rest/is_edited.php?page=PMID:$pmid";
	my $request = $mech->get($url);
	my $page = $mech->content;
	my $total;
	if ($page =~ /<revisions><total>(\d+)<\/total>/g) {
		$total = $1;
	}
	if ($total == 1) {
		return "(1 edit)";
	} 
	else { return "($total edits)"; }
}

sub PrintStopwordWarning {

    my $query = shift;
    my $words = shift;
    my $warncolor = shift;

    print $query->span({-style => "color:$warncolor;"},
		       "One or more stopwords have been found: $words");	
    print $query->br;
    print $query->span({-style => "color:$warncolor;"},
		       "Search results may be inaccurate (because of automatic exclusion of stopwords).");	
    print $query->br;
    print $query->span({-style => "color:$warncolor;"},
		       "Please remove stopwords from your query.");	
    print $query->p;
}

sub PrintTypeTabs {
	
	my $query = shift;
	my $num = shift;
	my $rev = shift;
	my $aux = new TextpressoTable;
	$aux->init;
	$aux->addtablerow();
	$aux->addtablerow(
			  $query->a({-href => '#all'}, "All: $num ") , 
			  $query->a({-href => '#review'}, "Review: $rev")
			);

	return $aux->maketable($query, tablestyle => 'borderless', valign => 'middle');
}


sub PrintGlobalLinkTable {

    my $query = shift;
    my %urls = @_;
    my @clr = ();
    $clr[0] = (DSP_HIGHLIGHT_COLOR)->{7};
    $clr[1] = (DSP_HIGHLIGHT_COLOR)->{1};
    $clr[2] = (DSP_HIGHLIGHT_COLOR)->{3};
    $clr[3] = (DSP_HIGHLIGHT_COLOR)->{4};
    $clr[4] = (DSP_HIGHLIGHT_COLOR)->{2};
    $clr[5] = (DSP_HIGHLIGHT_COLOR)->{5};
    $clr[6] = (DSP_HIGHLIGHT_COLOR)->{6};
    
    my @rows = ();
    my $color = 0;
    foreach my $txt (sort keys % urls) { 
        push @rows, $query->a({-href => $urls{$txt}, -target => "_blank"}, 
                              $query->span({-style => "background:white;color:$clr[$color];text-decoration:underline"},$txt));
        $color++;
    }
    my $glblnktbl = new TextpressoTable;
    $glblnktbl->init;
    $glblnktbl->addtablerow();
    $glblnktbl->addtablerow($query->span({-style => "font-weight:bold;"}, "Global links/files:"),
                            @rows); 

    return $glblnktbl->maketable($query, tablestyle => 'borderless', valign => 'middle');

}


sub gettext {

    my $literature = shift;
    my $field = shift;
    my $docid = shift;
    my $output = "";
    my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$literature} . '/' .
	DB_TEXT . '/' . (DB_DISPLAY_FIELDS)->{$field} . '/' . $docid;
    open (IN, "<$fn");
    while (my $line = <IN>) {
	$output .= $line;
    }
    close (IN);

    return $output;
}

sub getsentences {

    my $literature = shift;
    my $target = shift;
    my $docid = shift;
    my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$literature} . '/' .
	DB_TEXT . '/' . (DB_SEARCH_TARGETS)->{$target} . '/' . $docid;
    my @text = ();
    open (IN, "<$fn");
    while (my $line = <IN>) {
	chomp($line);
	push @text, $line;
    }
    close (IN);

    return @text;
}

sub preparesortresults {
    
    my $pLTK = shift;
    my $pResults = shift;
    my $sortcriterion = shift;
    
    my %scorelist = ();
    my %invlist = ();
    
    foreach my $ltk (keys % { $pLTK }) {
	(my $lit, my $tgt, my $key) = split(/\ -\ /, $ltk);
	if ($sortcriterion =~ /(score|hits)/i) {
	    my $score = 0;
	    foreach my $clstr (@{ $$pLTK{$ltk} }) {
		$score += $$pResults{$lit}{$key}{$tgt}{$clstr};
	    }
	    $scorelist{$ltk} = $score;
	} else {
	    my $string = substr(gettext($lit, $sortcriterion, $key), 0, 80);
	    $scorelist{$ltk} = $string;
	}
    }
    foreach my $ltk (keys % scorelist) {
	push @{$invlist{$scorelist{$ltk}}}, $ltk;
    }
    
    return %invlist;
}

sub highlighttext {

    my $text = shift;
    my $color = shift;
    my $var = shift;
    
    my $ldel = (GE_DELIMITERS)->{annotation_entry_left};
    my $rdel = (GE_DELIMITERS)->{annotation_entry_right};

    my $leftsub = "\<span style=\'font-weight:bold;color:black;\'\>";
    my $rightsub = "\<\/span\>";

    while ($text =~ s/($ldel)($var)($rdel)/$1$leftsub$3$rightsub$4/i) {}; # One bracket inside $var
    return $text;
}


sub makehighlightterms {

    my $tpquery = shift;
    my $mode = shift;
    my $lit = shift;
    my $tgt = shift;
    my $key = shift;
    my %ret = ();

    if ($mode eq 'keyword') {
	for (my $i = 0; $i < @{$tpquery->{type}}; $i++) {
	    if ($tpquery->type($i) eq 'keyword') {
		my @list = split (/\,/, $tpquery->data($i));
		foreach my $item (@list) {
		    $ret{($tpquery->exactmatch($i)) ? $item : $item . '\S*?'} = 1;
		}
	    }
	}
   } elsif ($mode eq 'category') {
	my $annfile = DB_ROOT . '/' . (DB_LITERATURE)->{$lit} . '/' .
	    DB_ANNOTATION . '/' . (DB_SEARCH_TARGETS)->{$tgt} . '/semantic/' . $key;
	undef $/;
	open (IN, "<$annfile");
	my $aline = <IN>;
	close (IN);
	$/ = "\n";
	my $boa = (GE_DELIMITERS)->{start_annotation};
	my $eoa = (GE_DELIMITERS)->{end_annotation};
	my @splits = split (/$eoa/, $aline);
	for (my $i = 0; $i < @{$tpquery->{type}}; $i++) {
	    if ($tpquery->type($i) eq 'category') {
		my @list = split (/\,/, $tpquery->data($i));
		foreach my $item (@list) {
		    foreach my $si (@splits) {
			if ($si =~ /\n$item /) {
			    (my $extract) = $si =~ /$boa\n(.+?)\n/;
			    $ret{$extract} = 1;
			}
		    }
		}
	    }
	}
    }

    return (keys % ret);
}


sub OldFilter
{	
    my $p_results = shift;
    my $filter_string = shift;
    
    my @filter_p = (); # Positive
    my @filter_n = (); # Negative
    
    my @terms = split /([\[\]])/, $filter_string;
    
    for (my $i=0; $i < @terms; $i+=4)
    {	
	my $term = $terms[$i];
	my $search_field = $terms[$i + 2];
	
	my $display_field_flag = 0;
	foreach my $db_display_field (keys % { (DB_DISPLAY_FIELDS) })
	{	if ($search_field eq $db_display_field)
		{	$display_field_flag = 1;
			last;
		    }
	    }
	
	my @entries = split /([-+])/, $term;
	
	my $include = 0;
	@filter_p = (); @filter_n = ();
	my $count_p = 0; my $count_n = 0;
	foreach my $entry (@entries)
	{
	    if ($entry eq "+")
	    {	$include = 1;
		next;
	    } elsif ($entry eq "-")
	    {	$include = 0;
		next;
	    }
	    
	    $entry =~ s/\"(.*)\"/$1/;
	    
	    if ($include == 1 && $entry =~ /\w+/)
	    {	$filter_p[$count_p] = $entry;
		$count_p++;
	    } elsif ($include == 0 && $entry =~ /\w+/)
	    {	$filter_n[$count_n] = $entry;
		$count_n++;
	    }
	}
	
	
	if ($display_field_flag)
	{	
	    foreach my $lit (keys % { $p_results })
	    {	foreach my $key (keys % { ($$p_results{$lit}) })
		{	
		    my $database_entry = gettext($lit, $search_field, $key);
		    
		    foreach (@filter_p)
		    {	if ((/\w+/) && ! ($database_entry =~ /$_/i))
			{	
			    foreach my $tgt (keys % { $$p_results{$lit}{$key} })
			    {	foreach my $sen (keys % { $$p_results{$lit}{$key}{$tgt} })
				{	delete $$p_results{$lit}{$key}{$tgt}{$sen};
				    }
				delete $$p_results{$lit}{$key}{$tgt};
			    }
			    delete $$p_results{$lit}{$key};
			}
		    }
		    
		    foreach (@filter_n)
		    {	if ((/\w+/) && $database_entry =~ /$_/i)
			{	
			    foreach my $tgt (keys % { $$p_results{$lit}{$key} })
			    {	foreach my $sen (keys % { $$p_results{$lit}{$key}{$tgt} })
				{	delete $$p_results{$lit}{$key}{$tgt}{$sen};
				    }
				delete $$p_results{$lit}{$key}{$tgt};
			    }
			    delete $$p_results{$lit}{$key};
			}
		    }
		}
	    }
	}
	elsif ($search_field eq "sentence")
	{	foreach my $search_target ( @{(DB_SEARCH_TARGETS_DEFAULTS)} ) # abstract, body, title
		{	
		    foreach my $f_n (@filter_n)
		    {	
			$f_n =~ s/ /\-/g;
			$f_n =~ /(\w{2})/;
			(my $letter1, my $letter2) = split //, $1;
			foreach my $lit (keys % { $p_results })
			{	
			    # Make the sentence filter case-insensitive
			    $letter1 =~ tr/A-Z/a-z/;
			    my $small_letter = $letter1;
			    $letter1 =~ tr/a-z/A-Z/;
			    my $capital_letter = $letter1;
			    
			    # First letter small
			    $f_n =~ s/^$capital_letter/$small_letter/;
			    my $infiles_small = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				. "keyword/" . $small_letter . "/" . $letter2 . "/" . $f_n; 
			    my @infilenames = <$infiles_small*>;
			    
			    # First letter CAPS
			    $f_n =~ s/^$small_letter/$capital_letter/;
			    my $infiles_capital = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				. "keyword/" . $capital_letter . "/" . $letter2 . "/" . $f_n; 
			    my @infilenames_c = <$infiles_capital*>;
			    foreach (@infilenames_c)
			    {	push @infilenames, $_;
			    }
			    
			    # All CAPS
			    my $caps_filter = $f_n;
			    $caps_filter =~ tr/a-z/A-Z/;
			    $caps_filter =~ /(\w{2})/;
			    ($letter1, $letter2) = split //, $1;
			    my $tmp = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				. "keyword/" . $letter1 . "/" . $letter2 . "/" . $caps_filter; 
			    my @caps = <$tmp*>;
			    foreach (@caps)
			    {	
				push @infilenames, $_;
			    }
			    
			    foreach my $in_file (@infilenames)
			    {	
				open (IN, "<$in_file");
				while (<IN>)
				{	
				    my $line = $_;
				    my @wbpaper_sen = split /,/, $line;
				    
				    my $wbpaperid = shift @wbpaper_sen;
				    
				    if (defined($$p_results{$lit}{$wbpaperid}{$search_target}))
				    {	foreach my $s (@wbpaper_sen)
					{	
					    $s =~ s/(s\d+)\s*/$1/; # whitespace gets introduced if last entry in index file 
					    if (defined($$p_results{$lit}{$wbpaperid}{$search_target}{$s}))
					    {
						delete $$p_results{$lit}{$wbpaperid}{$search_target}{$s};
					    }
					}
				    }
				}
			    }
			}
		    }
		    
		    foreach my $f_p (@filter_p)
		    {	$f_p =~ s/ /\-/g;
			$f_p =~ /(\w{2})/;
			(my $letter1, my $letter2) = split //, $1;
			foreach my $lit (keys % { $p_results })
			{	
			    # Make the sentence filter case-insensitive
			    $letter1 =~ tr/A-Z/a-z/;
			    my $small_letter = $letter1;
			    $letter1 =~ tr/a-z/A-Z/;
			    my $capital_letter = $letter1;
			    
			    # All small
			    $f_p =~ s/^$capital_letter/$small_letter/;
			    my $infiles_small = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				. "keyword/" . $small_letter . "/" . $letter2 . "/" . $f_p; 
			    my @infilenames = <$infiles_small*>;
			    
			    # First letter CAP
			    $f_p =~ s/^$small_letter/$capital_letter/;
			    my $infiles_capital = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				. "keyword/" . $capital_letter . "/" . $letter2 . "/" . $f_p; 
			    my @infilenames_c = <$infiles_capital*>;
			    foreach (@infilenames_c)
			    {	push @infilenames, $_;
			    }
			    
			    # All CAPS
			    my $caps_filter = $f_p;
			    $caps_filter =~ tr/a-z/A-Z/;
			    $caps_filter =~ /(\w{2})/;
			    ($letter1, $letter2) = split //, $1;
			    my $tmp = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				. "keyword/" . $letter1 . "/" . $letter2 . "/" . $caps_filter; 
			    my @caps = <$tmp*>;
			    foreach (@caps)
			    {	
				push @infilenames, $_;
			    }
			    
			    my %Paperid_Sen;
			    foreach (@infilenames)
			    {	open (IN, "<$_");
				while (<IN>)
				{
				    chomp;
				    my $line = $_;
				    my @entries = split /,/, $line;
				    my $paperid = shift @entries;
				    foreach my $sen (@entries)
				    {	$sen =~ s/(s\d+)\s*/$1/;
					$Paperid_Sen{$paperid}{$sen} = 1;
				    }
				}
			    }
			    
			    foreach my $wbpaperid (keys %{ $$p_results{$lit} })
			    {	
				foreach my $sen (keys %{ $$p_results{$lit}{$wbpaperid}{$search_target} })
				{
				    if (! $Paperid_Sen{$wbpaperid}{$sen})
				    {	delete $$p_results{$lit}{$wbpaperid}{$search_target}{$sen};
				    }
				}
			    }
			}
		    }
		}
	    }
    }
    
    my @filter_p = (); # Positive
    return;
}


sub Filter
{	
    my $p_results = shift;
    my $p_filtered_results = shift;
    my $filter_string = shift;
    
    my @filter_p = (); # Positive
    my @filter_n = (); # Negative
    
    my @terms = split /([\[\]])/, $filter_string;
    
    my $stopwords = TextpressoDatabaseSearch::getstopwords(DB_STOPWORDS);
    
    for (my $i=0; $i < @terms; $i+=4)
    {	
	my $f_string = $terms[$i];
	my $search_field  = $terms[$i + 2];
	
	# Get the filters
	my @entries = split /([-+])/, $f_string;
	my $positive = 0; @filter_p = (); @filter_n = (); my $count_p = 0; my $count_n = 0;
	foreach my $entry (@entries)
	{
	    if ($entry eq "+")
	    {	$positive = 1;
		next;
	    } elsif ($entry eq "-")
	    {	$positive = 0;
		next;
	    }
	    
	    $entry =~ s/\"(.*)\"/$1/;
	    
	    if ($positive == 1 && $entry =~ /\w+/)
	    {	$filter_p[$count_p] = $entry;
		$count_p++;
	    } elsif ($positive == 0 && $entry =~ /\w+/)
	    {	$filter_n[$count_n] = $entry;
		$count_n++;
	    }
	}
	
	# Identify $search_field
	my $display_field_flag = 0;
	foreach my $db_display_field (keys % { (DB_DISPLAY_FIELDS) })
	{	if ($search_field eq $db_display_field)
		{	$display_field_flag = 1;
			last;
		    }
	    }
	
	if ($display_field_flag)
	{	
	    foreach my $lit (keys % { $p_results })
	    {	foreach my $key (keys % { ($$p_results{$lit}) })
		{	
		    my $database_entry = gettext($lit, $search_field, $key);
		    
		    foreach (@filter_p)
		    {	if ((/\w+/) && ! ($database_entry =~ /$_/i))
			{	
			    foreach my $tgt (keys % { $$p_results{$lit}{$key} })
			    {	foreach my $sen (keys % { $$p_results{$lit}{$key}{$tgt} })
				{	delete $$p_filtered_results{$lit}{$key}{$tgt}{$sen};
				    }
				delete $$p_filtered_results{$lit}{$key}{$tgt};
			    }
			    delete $$p_filtered_results{$lit}{$key};
			}
		    }
		    
		    foreach (@filter_n)
		    {	if ((/\w+/) && $database_entry =~ /$_/i)
			{	
			    foreach my $tgt (keys % { $$p_results{$lit}{$key} })
			    {	foreach my $sen (keys % { $$p_results{$lit}{$key}{$tgt} })
				{	delete $$p_filtered_results{$lit}{$key}{$tgt}{$sen};
				    }
				delete $$p_filtered_results{$lit}{$key}{$tgt};
			    }
			    delete $$p_filtered_results{$lit}{$key};
			}
		    }
		}
	    }
	}
	
	elsif ($search_field eq "sentence")
	{
	    foreach my $lit (keys % { $p_results })
	    {	
		foreach my $search_target ( @{(DB_SEARCH_TARGETS_DEFAULTS)} ) # abstract, body, title
		{	
		    foreach my $f_n (@filter_n)
		    {
			my %present;
			my $no_of_words = 0;
			my $no_of_nonstop_words = 0;
			
			# If $f_n is a phrase, then store individual words in @words
			my @words;
			push @words, $f_n;
			if ($f_n =~ / /)
			{	
			    @words = split / /, $f_n;
			}
			$no_of_words = @words;
			
			foreach my $w (@words)
			{	
			    if (! ($stopwords =~ /$w/i))
			    {
				$no_of_nonstop_words++;
				$w =~ /(\w{2})/;
				(my $letter1, my $letter2) = split //, $1;
				# Make the sentence filter case-insensitive
				$letter1 =~ tr/A-Z/a-z/;
				my $small_letter = $letter1;
				$letter1 =~ tr/a-z/A-Z/;
				my $capital_letter = $letter1;
				
				# First letter small
				$w =~ s/^$capital_letter/$small_letter/;
				my $infiles_small = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				    . "keyword/" . $small_letter . "/" . $letter2 . "/" . $w; 
				my @infilenames = <$infiles_small*>;
				
				# First letter CAPS
				$w =~ s/^$small_letter/$capital_letter/;
				my $infiles_capital = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				    . "keyword/" . $capital_letter . "/" . $letter2 . "/" . $w; 
				my @infilenames_c = <$infiles_capital*>;
				foreach (@infilenames_c)
				{	push @infilenames, $_;
				    }
				
				# All CAPS
				my $caps_filter = $w;
				$caps_filter =~ tr/a-z/A-Z/;
				$caps_filter =~ /(\w{2})/;
				($letter1, $letter2) = split //, $1;
				my $tmp = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				    . "keyword/" . $letter1 . "/" . $letter2 . "/" . $caps_filter; 
				my @caps = <$tmp*>;
				foreach (@caps)
				{	
				    push @infilenames, $_;
				}
				
				foreach my $in_file (@infilenames)
				{	
				    open (IN, "<$in_file");
				    while (<IN>)
				    {	
					my @wbpaper_sen = split /,/, $_;
					
					my $wbpaperid = shift @wbpaper_sen;
					
					if (defined($$p_results{$lit}{$wbpaperid}{$search_target}))
					{	foreach my $s (@wbpaper_sen)
						{	
						    $s =~ s/(s\d+)\s*/$1/; # whitespace gets introduced if last entry in index file 
						    if (defined($$p_results{$lit}{$wbpaperid}{$search_target}{$s}))
						    {
							$present{$s}{$wbpaperid}{$w} = 1;
						    }
						}
					    }
				    }
				}
				
			    }
			}
			
			if ($no_of_words > 1) # Check for adjacency of words
			{
			    foreach my $s (keys %present)
			    {
				foreach my $wbid (keys % {$present{$s}})
				{
				    my @w3 = keys %{$present{$s}{$wbid}};
				    my $w3_size = @w3;
				    if ($w3_size == $no_of_nonstop_words)
				    {
					$s =~ /s(\d+)/;
					my $sen_no = $1;
					
					my $file = DB_ROOT . DB_LITERATURE->{$lit} . "/" . "txt" . "/" . "$search_target" . "/" . $wbid;
					open (INPUT, "<$file") || print "Could not open $file<BR>";
					
					my $c=0;
					while (<INPUT>)
					{	
					    $c++;
					    if ($c == $sen_no)
					    {
						if (/$f_n/i)
						{
						    delete $$p_filtered_results{$lit}{$wbid}{$search_target}{$s}; 
						}
					    }
					}
				    }
				}
			    }
			}
			else
			{
			    foreach my $s (keys %present)
			    {
				foreach my $wbid (keys % {$present{$s}})
				{
				    my @w3 = keys %{$present{$s}{$wbid}};
				    my $w3_size = @w3;
				    if ($w3_size == $no_of_nonstop_words)
				    {
					delete $$p_filtered_results{$lit}{$wbid}{$search_target}{$s};
				    }
				}
			    }
			}
			
		    }
		    
		    foreach my $f_p (@filter_p)
		    {
			my %present;
			my $no_of_words = 0;
			my $no_of_nonstop_words = 0;
			
			# If $f_p is a phrase, then store individual words in @words
			my @words;
			push @words, $f_p;
			if ($f_p =~ / /)
			{	
			    @words = split / /, $f_p;
			}
			$no_of_words = @words;
			
			foreach my $w (@words)
			{	
			    if (! ($stopwords =~ /$w/i))
			    {
				$no_of_nonstop_words++;
				$w =~ /(\w{2})/;
				(my $letter1, my $letter2) = split //, $1;
				# Make the sentence filter case-insensitive
				$letter1 =~ tr/A-Z/a-z/;
				my $small_letter = $letter1;
				$letter1 =~ tr/a-z/A-Z/;
				my $capital_letter = $letter1;
				
				# First letter small
				$w =~ s/^$capital_letter/$small_letter/;
				my $infiles_small = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				    . "keyword/" . $small_letter . "/" . $letter2 . "/" . $w; 
				my @infilenames = <$infiles_small*>;
				
				# First letter CAPS
				$w =~ s/^$small_letter/$capital_letter/;
				my $infiles_capital = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				    . "keyword/" . $capital_letter . "/" . $letter2 . "/" . $w; 
				my @infilenames_c = <$infiles_capital*>;
				foreach (@infilenames_c)
				{	push @infilenames, $_;
				    }
				
				# All CAPS
				my $caps_filter = $w;
				$caps_filter =~ tr/a-z/A-Z/;
				$caps_filter =~ /(\w{2})/;
				($letter1, $letter2) = split //, $1;
				my $tmp = DB_ROOT . (DB_LITERATURE)->{$lit} . DB_INDEX . $search_target . "/" 
				    . "keyword/" . $letter1 . "/" . $letter2 . "/" . $caps_filter; 
				my @caps = <$tmp*>;
				foreach (@caps)
				{	
				    push @infilenames, $_;
				}
				
				foreach my $in_file (@infilenames)
				{	
				    open (IN, "<$in_file");
				    while (<IN>)
				    {	
					my @wbpaper_sen = split /,/, $_;
					
					my $wbpaperid = shift @wbpaper_sen;
					
					if (defined($$p_results{$lit}{$wbpaperid}{$search_target}))
					{	foreach my $s (@wbpaper_sen)
						{	
						    $s =~ s/(s\d+)\s*/$1/; # whitespace gets introduced if last entry in index file 
						    if (defined($$p_results{$lit}{$wbpaperid}{$search_target}{$s}))
						    {
							$present{$s}{$wbpaperid}{$w} = 1;
						    }
						}
					    }
				    }
				}
				
			    }
			}
			
			if ($no_of_words > 1) # Check for adjacency of words
			{
			    foreach my $s (keys %present)
			    {
				foreach my $wbid (keys % {$present{$s}})
				{
				    my @w3 = keys %{$present{$s}{$wbid}};
				    my $w3_size = @w3;
				    if ($w3_size == $no_of_nonstop_words)
				    {
					$s =~ /s(\d+)/;
					my $sen_no = $1;
					
					my $file = DB_ROOT . DB_LITERATURE->{$lit} . "/" . "txt" . "/" . "$search_target" . "/" . $wbid;
					open (INPUT, "<$file") || print "Could not open $file<BR>";
					
					my $c=0;
					while (<INPUT>)
					{	
					    $c++;
					    if ($c == $sen_no)
					    {
						if (! (/$f_p/i))
						{
						    foreach (keys % {$present{$s}{$wbid}})
						    {
							delete $present{$s}{$wbid}{$_};
						    }
						}
					    }
					}
				    }
				}
			    }
			}
			
			foreach my $k (keys % { ($$p_results{$lit}) })
			{	foreach my $s (keys % { $$p_results{$lit}{$k}{$search_target} })
				{	
				    my @words = keys % {$present{$s}{$k}};
				    if (@words != $no_of_nonstop_words)
				    {
					delete $$p_filtered_results{$lit}{$k}{$search_target}{$s};
				    }
				}
			    }			
       		    }
		    
		}
	    }
	}
    }
    
    return;
}


sub ascending {  $a <=> $b }
sub descending {  $b <=> $a }
sub sentencewise {

    (my $c = $a) =~ s/s//g;
    (my $d = $b) =~ s/s//g;
    $c <=> $d;
}

1;
