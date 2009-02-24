
package TextpressoSystemTasks;

# Package provide class and methods for
# tasks related to processing and maintaining of
# the build for the Textpresso system.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena,
#     with additions by Arun Rangarajan.
#
use strict;
use TextpressoGeneralTasks;
use TextpressoSystemGlobals;
use TextpressoGeneralGlobals;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(AddToIndex AddToAnnotation AddToAnnotationInOneProcess RemoveFromIndex RemoveFromAnnotation Tokenizer SpecialReplacements RemovePreprocessingTags);

sub AddToIndex {
    
    use File::Basename;
    
    my $infile = shift;
    my $outfield = shift;
    my $itype = shift;
    $outfield .= (SY_INDEX_TYPE)->{$itype};
    (my $fname, my $fdir, my $fsuf) = fileparse($infile);
    
    if ($itype eq 'keyword') {
	my %idlist = KeywordParse($infile);
	foreach my $key (keys % idlist) {
	    my $sd1 = substr($key, 0, 1);
	    if (! -d "$outfield$sd1/") {
		mkdir("$outfield$sd1/");
	    }
	    my $sd2 = substr($key, 1, 1);
	    if (! -d "$outfield$sd1/$sd2/") {
		mkdir ("$outfield$sd1/$sd2/");
	    }
	    my $outname = $outfield . $sd1 . '/' . $sd2 . '/' . $key;
	    FlushOutToIndexFile ($outname, $fname, @{$idlist{$key}});
	}
    } elsif ($itype eq 'semantic') {
	my %idlist = AnnotationParse($infile);
	my $pcat = (GE_DELIMITERS)->{parent_category};
	foreach my $cat (keys % idlist) {
	    foreach my $att (keys %{$idlist{$cat}}) {
		if ($att =~ /$pcat/) {
		    my $outname = $outfield . (SY_INDEX_SUBTYPE)->{categories} . $cat;
		    FlushOutToIndexFile ($outname, $fname, @{$idlist{$cat}{$att}});
		} 
		else {
		    my $sd1 = (SY_INDEX_SUBTYPE)->{attributes} . $cat;
		    if (! -d "$outfield$sd1/") {
			mkdir("$outfield$sd1/");
		    }
		    (my $sd2) = $att =~ /(.+?)=/;
		    if (! -d "$outfield$sd1/$sd2/") {
			mkdir ("$outfield$sd1/$sd2/");
		    }
		    (my $aux) = $att =~ /=\'(.+?)\'/;
		    my @values = split (/\|/, $aux);
		    foreach my $value (@values) {
			my $outname = $outfield . $sd1 . '/' . $sd2 . '/' . $value;
			FlushOutToIndexFile ($outname, $fname, @{$idlist{$cat}{$att}});
		    }   
		}
	    }
	}
    } elsif ($itype eq 'grammatical') {
        # do grammatical-specific indexing here, or combine with
        # above
    }
}

sub FlushOutToIndexFile {
    
    my $outname = shift;
    my $fname = shift;
    open (OUT, ">>$outname");
    print OUT $fname;
    foreach (@_) {
	print OUT ',', $_;
    }
    print OUT "\n";
    close (OUT);
    
}

sub AddToAnnotation {
    
    use File::Basename;
    
    my $infile = shift;
    my $outfield = shift;
    my $itype = shift;
    my %lexicon = shift;
    $outfield .= (SY_ANNOTATION_TYPE)->{$itype};
    
    if ($itype eq 'semantic') {
	
	# do semantic-specific annotation here
	
	(my $outfile, my $dummy1, my $dummy2) = fileparse($infile);
	open (OUT, ">$outfield$outfile");
	
	my @lines = GetLines($infile, 1);
	my $totallines = @lines;
	
	# for dual-processor systems, process with two children
	
	my $ppid = $$;
	my $pid1;
    	my $pid2;
	unless ($pid1 = fork) { # child 1
  	    defined($pid1) or die "Cannot fork: $!";
	    open (OUT1, ">/tmp/$ppid-textpresso-child1.out");
	    for (my $i = 0; $i < $totallines/2; $i++) {
		AnnotateAndPrintLine (\*OUT1, \%lexicon, $i + 1, $lines[$i]);
   	    }  
  	    close (OUT1);
	    exit;
	}  
	unless ($pid2 = fork) { # child 2
	    defined($pid2) or die "Cannot fork: $!";
	    open (OUT2, ">/tmp/$ppid-textpresso-child2.out");
	    for (my $i = int($totallines/2 + 0.5) ; $i < $totallines; $i++) {
		AnnotateAndPrintLine (\*OUT2, \%lexicon, $i + 1, $lines[$i]);
	    }
	    close (OUT2);
	    exit;
	}
	
	waitpid($pid1, 0);
	waitpid($pid2, 0);
	# catch children's output
	open (OUT1, "</tmp/$ppid-textpresso-child1.out");
	my @childout = <OUT1>;
	close (OUT1);
	print OUT @childout;
	open (OUT2, "</tmp/$ppid-textpresso-child2.out");
	@childout = <OUT2>;
	close (OUT2);
	print OUT @childout;
	close (OUT);
    } elsif ($itype eq 'grammatical') {
	
	# do grammatical-specific annotation here
	
    }
    
}

sub AddToAnnotationInOneProcess {

    use File::Basename;
    
    my $infile = shift;
    my $outfield = shift;
    my $itype = shift;
    my $pLexicon = shift;
    
    $outfield .= (SY_ANNOTATION_TYPE)->{$itype};
    
    if ($itype eq 'semantic') {
	
	# do semantic-specific annotation here
	
	(my $outfile, my $dummy1, my $dummy2) = fileparse($infile);
	open (OUT, ">$outfield$outfile");
	
	my @lines = GetLines($infile, 1);
	my $totallines = @lines;
	
	for (my $i = 0; $i < $totallines; $i++) {
	    AnnotateAndPrintLine (\*OUT, $i + 1, $lines[$i], $pLexicon);
	}  
	close (OUT);
    }
}


sub AnnotateAndPrintLine {
    
    local *OUT = shift;    
    my $sentenceid = shift;
    my $line = shift;
    my $pLexicon = shift;
    
    my $allexceptions = join (" ", @{(SY_MARKUP_EXCEPTIONS)}) . " ";
    my $ssl = (GE_DELIMITERS)->{start_sentence_left};
    my $ssr = (GE_DELIMITERS)->{start_sentence_right};
    my $boa = (GE_DELIMITERS)->{start_annotation};
    my $eoa = (GE_DELIMITERS)->{end_annotation};
    print OUT $ssl, $sentenceid, $ssr, "\n";
    
    my $dels = (GE_DELIMITERS)->{word};
    my @words = split /([$dels])/, $line; 
    # Eg. $line = "Growth hormone-releasing hormones are found."
    # @words = {Growth, ,hormone,-,releasing, ,hormones, ,are, ,found.}
    
    for (my $startindex = 0; $startindex < @words; $startindex += 2) {
	my $term = $words[$startindex];
	
	$term = "\\\(" if ($term eq "\(");
	$term = "\\\)" if ($term eq "\)");
	$term = "\\\[" if ($term eq "\[");
	$term = "\\\]" if ($term eq "\]");
	
	# Set the length of the longest string to be matched
	my $limit = @words;
	if ($limit > $startindex + 2*SY_MAX_NGRAM_SIZE) { # 2 because we have the delimiters in @words
	    $limit = $startindex + 2*SY_MAX_NGRAM_SIZE;
	}
	
	for (my $i = $startindex + 1; $i < $limit + 1; $i += 2) {
	    if ( keys % { $$pLexicon{$term} } ) {
		my @categories = ();
		foreach my $aux (keys % { $$pLexicon{$term} }) {
		    if ($allexceptions !~ /$aux /) {
			push @categories, $aux;
		    }
		}
		my $term1 = $term;
		$term1 = "\(" if ($term eq "\\\(");
		$term1 = "\)" if ($term eq "\\\)");
		$term1 = "\[" if ($term eq "\\\[");
		$term1 = "\]" if ($term eq "\\\]");
		
		print OUT "$boa\n";
		print OUT $term1, "\n";
		print OUT $startindex/2, "\n";
		foreach my $cat (@categories) {
		    print OUT $cat, " ";
		    print OUT "@{$$pLexicon{$term}{$cat}}", "\n";
		}
		print OUT "$eoa\n";
	    } elsif (HasPreprocessingTags($term, @{(SY_PREPROCESSING_TAGS)})) {
		my %auxlist = ProcessPreprocessingTags($term,  @{(SY_PREPROCESSING_TAGS)});
		foreach my $cat (keys % auxlist) {
		    my $term1 = $auxlist{$cat};
		    my $term2 = $term1;
		    $term1 = "\(" if ($term1 eq "\\\(");
		    $term1 = "\)" if ($term1 eq "\\\)");
		    $term1 = "\[" if ($term1 eq "\\\[");
		    $term1 = "\]" if ($term1 eq "\\\]");
		
		    print OUT "$boa\n";
		    print OUT $term1, "\n";
		    print OUT $startindex/2, "\n";		
		    print OUT $cat, " ";
		    if (keys % { $$pLexicon{$term2} } ) {
			print OUT "@{$$pLexicon{$term2}{$cat}}";
		    } else {
			delete $$pLexicon{$term2}
		    }
		    print OUT "\n";
		}
		print OUT "$eoa\n";
		delete $$pLexicon{$term};
	    } else {
		delete $$pLexicon{$term};
	    }
	    $term .= $words[$i] . $words[$i+1];
	}
    }
    my $eos = (GE_DELIMITERS)->{end_sentence};  
    print OUT "$eos\n";
}


sub AnnotateAndPrintLineOld {
    
    local *OUT = shift;    
    my $sentenceid = shift;
    my $line = shift;
    my $pLexicon = shift;
    
    my $usual_del = (GE_DELIMITERS)->{word_usual};
    my $other_del = (GE_DELIMITERS)->{word_other};
    my @words = split /$usual_del/, $line;
    
    my $ssl = (GE_DELIMITERS)->{start_sentence_left};
    my $ssr = (GE_DELIMITERS)->{start_sentence_right};
    my $boa = (GE_DELIMITERS)->{start_annotation};
    my $eoa = (GE_DELIMITERS)->{end_annotation};
    print OUT $ssl, $sentenceid, $ssr, "\n";
    
    my $term = "";
    for (my $startindex=0; $startindex<= $#words; $startindex++) {
	$term = $words[$startindex];
	
	$term = "\\\(" if ($term eq "\(");
	$term = "\\\)" if ($term eq "\)");
	$term = "\\\[" if ($term eq "\[");
	$term = "\\\]" if ($term eq "\]");
	
	my $already_annotated = 0;
	my @subwords = ();
	if ($term =~ m/$other_del/) {
	    @subwords = split /$other_del/, $term;
	    for (my $sub_startindex = 0; $sub_startindex <= @subwords ; $sub_startindex++) {
		my $sub_term = ();
		for (my $subindex = $sub_startindex; $subindex <= @subwords ; $subindex++) {
		    $sub_term .= $subwords[$subindex];
		    
		    if ( keys % { $$pLexicon{$sub_term} } ) {
			my @categories = (keys % { $$pLexicon{$sub_term} });
			
			print OUT "$boa\n";
			print OUT $sub_term, "\n";
			print OUT $startindex + $sub_startindex, "\n"; 
			foreach my $cat (@categories) {
			    print OUT $cat, " ";
			    print OUT "@{$$pLexicon{$sub_term}{$cat}}", "\n";
			}
			print OUT "$eoa\n";
			$already_annotated = 1;
		    } else {
			delete $$pLexicon{$sub_term};
		    }
		    $sub_term .= $other_del;
		}
	    }
	} 
	
	my $limit = @words+1;
	if ($limit > $startindex + SY_MAX_NGRAM_SIZE) {
	    $limit = $startindex + SY_MAX_NGRAM_SIZE;
	}
	
	for (my $i = $startindex + 1; $i <= $limit; $i++) {
	    if (!($already_annotated == 1)) {
		if ( keys % { $$pLexicon{$term} } ) {
		    my @categories = (keys % { $$pLexicon{$term} });
		    my $term1 = $term;
		    $term1 = "\(" if ($term eq "\\\(");
		    $term1 = "\)" if ($term eq "\\\)");
		    $term1 = "\[" if ($term eq "\\\[");
		    $term1 = "\]" if ($term eq "\\\]");
		    
		    print OUT "$boa\n";
		    print OUT $term1, "\n";
		    print OUT $startindex, "\n";
		    foreach my $cat (@categories) {
			print OUT $cat, " ";
			print OUT "@{$$pLexicon{$term}{$cat}}", "\n";
		    }
		    print OUT "$eoa\n";
		} else {
		    delete $$pLexicon{$term};
		}
	    }
	    $term .= $usual_del . $words[$i];
	    $already_annotated = 0;
	}
    }
    
    my $eos = (GE_DELIMITERS)->{end_sentence};  
    print OUT "$eos\n";
}

sub RemoveFromIndex {
    
    use File::Basename;
    
    my $infile = shift;
    my $outfield = shift;
    my $itype = shift;
    $outfield .= (SY_INDEX_TYPE)->{$itype};
    (my $fname, my $fdir, my $fsuf) = fileparse($infile);
    
    if ($itype eq 'keyword') {
    	
	my %idlist = KeywordParse($infile);
    	
	foreach my $key (keys % idlist) {
	    my $sd1 = substr($key, 0, 1);
	    my $sd2 = substr($key, 1, 1);
	    my $outname = $outfield . $sd1 . '/' . $sd2 . '/' . $key;
	    ZapFromIndexFile ($outname, $fname);
	}
	
    } elsif ($itype eq 'semantic') {
	my %idlist = AnnotationParse($infile);
	my $pcat = (GE_DELIMITERS)->{parent_category};
	foreach my $cat (keys % idlist) {
	    foreach my $att (keys %{$idlist{$cat}}) {
		if ($att =~ /$pcat/) {
		    my $outname = $outfield . (SY_INDEX_SUBTYPE)->{categories} . $cat;
		    ZapFromIndexFile ($outname, $fname);
		} else {
		    my $sd1 = (SY_INDEX_SUBTYPE)->{attributes} . $cat;
		    (my $sd2) = $att =~ /(.+?)=/;
		    (my $aux) = $att =~ /=\'(.+?)\'/;
		    my @values = split (/\|/, $aux);
		    foreach my $value (@values) 
		    {
			my $outname = $outfield . $sd1 . '/' . $sd2 . '/' . $value;
			ZapFromIndexFile ($outname, $fname);
		    }
		} 
	    }
    	}
    } elsif ($itype eq 'grammatical') {
	# do grammatical-specific removing here, or combine with
	# above
    }
    
}

sub ZapFromIndexFile {
    
    my $outname = shift;
    my $fname = shift;
    
    my @lines = GetLines ($outname, 0);
    open (OUT, ">$outname");
    foreach my $line (@lines) {
	if ($line !~ /$fname/) {
	    print OUT $line;
	}
    }
    close (OUT);
    
}

sub RemoveFromAnnotation {
    
    use File::Basename;
    
    my $infile = shift;
    my $outfield = shift;
    my $itype = shift;
    $outfield .= (SY_ANNOTATION_TYPE)->{$itype};
    
    (my $outfile, my $dummy1, my $dummy2) = fileparse($infile);
    unlink("$outfield$outfile");
    
}

sub AddToSupplementals {}

sub RemoveFromSupplementals {}

sub KeywordParse {

    my $infile = shift;
    my %idlist = ();
    
    my $stpwrdfname = SY_ROOT . (SY_SUBROOTS)->{etc} . 'stopwords';
    my %stopwords = GetStopWords($stpwrdfname);
    my @lines = GetLines($infile, 0);
    for (my $i = 0; $i < @lines; $i++) {
	my @items = GetItemList($lines[$i]);
	my $lineid = $i + 1;
	foreach my $entry (@items) {
	    $entry =~ s/\s//g;
	    $entry =~ s/^-//g;
	    $entry =~ s/-$//g;
	    if ((length($entry) > 1) && 
		(substr($entry, 0, 1) =~ /\w/) && 
		(!$stopwords{"\L$entry\E"})) {
		push @{$idlist{$entry}}, 's' . $lineid;
	    }
	}
    }
    return %idlist;
}

sub AnnotationParse {
    
    my $infile = shift;
    my %list = ();
    
    my $inline = join ('', GetLines($infile, 0));
    my $eos = (GE_DELIMITERS)->{end_sentence};	
    my @sentences = split (/$eos\n/, $inline);
    my $pcat = (GE_DELIMITERS)->{parent_category};
    my $ssl = (GE_DELIMITERS)->{start_sentence_left};
    my $ssr = (GE_DELIMITERS)->{start_sentence_right};
    my $boa = (GE_DELIMITERS)->{start_annotation};
    my $eoa = (GE_DELIMITERS)->{end_annotation};
    foreach my $sentence (@sentences) {
	(my $sid) = $sentence =~ /$ssl(\d+)$ssr/;
	my @auxlines =  split (/$eoa\n/, $sentence);
	my @annotations = ();
	foreach my $aux (@auxlines) {
	    $aux =~ s/\A.*$boa\n//s;
	    my @lines = split (/\n/, $aux);
	    for (my $i = 2; $i < @lines; $i++) {
		chomp($lines[$i]);
		push @annotations, $lines[$i];
	    }
	}
	foreach my $annotation (@annotations) {
	    (my $category, my @attributes) = split (/ /, $annotation);
	    push @{$list{$category}{$pcat}}, 's' . $sid;
	    foreach my $attribute (@attributes) {
		push @{$list{$category}{$attribute}}, 's' . $sid;
	    }
	}
    }
    return %list;
    
}

sub GetItemList {
    
    my $line = shift;
    my $ked = (GE_DELIMITERS)->{keyword_entry};
    my @itemlist = split (/[$ked]+/, $line);
    my @cleanedlist = ();
    foreach my $item (@itemlist) {
        if ($item =~ /.+/) { push @cleanedlist, $item }
    }
    return @cleanedlist;
}

sub Tokenizer {
    
    my @incoming = @_;
    my $line = join ("", @incoming);

    # few things to begin with..
    
    # joins words hyphenated by the end of line
    $line =~ s/([a-z]+)- *\n+([a-z]+)/$1$2/g;
    # gets rid of hyphen in word, hypen, space, eg homo- and heterodimers
    $line =~ s/(\w+)- +/$1 /g;
    
    # deal with a period
    
    # gets rid of p.  after sing. capit. letters ( M. Young -> M Young)
    $line =~ s/(\b[A-Z])\./$1/g;
    # protect the "ca. <NUMBER>" notation!!!
    $line =~ s/( ca)\.( \d+)/$1$2/g;
    # gets rid of alot of extraneous periods within sentences ... 
    $line =~ s/e\.g\./eg/g;
    $line =~ s/i\.e\./ie/g;       
    $line =~ s/([Aa]l)\./$1/g;
    $line =~ s/([Ee]tc)\./$1/g;  
    $line =~ s/([Ee]x)\./$1/g;
    $line =~ s/([Vv]s)\./$1/g;
    $line =~ s/([Nn]o)\./$1/g;
    $line =~ s/([Vv]ol)\./$1/g;
    $line =~ s/([Ff]igs?)\./$1/g;
    $line =~ s/([Ss]t)\./$1/g;
    $line =~ s/([Cc]o)\./$1/g;
    $line =~ s/([Dd]r)\./$1/g;
    
    # now get rid of any newline characters, but protect already 
    # recognized end of sentence

    $line =~ s/ \. \n/_PERIOD_EOS__/g;
    $line =~ s/ \? \n/_QMARK_EOS__/g;
    $line =~ s/ \! \n/_EMARK_EOS__/g;
    
    # replaces new line character with a space
    $line =~ s/\n/ /g;
    
    # "protect" instances of periods that do not 
    # mark the end of a sentence by substituting 
    # an underscore for the following space i.e. 
    # ". " becomes "._"
    
    # general rule...
    # protect any period followed by a space then a small letter
    $line =~ s/\. ([a-z])/\._$1/g;
    
    # special instances not caught by general rules...
    # EXCEPTION; unprotect those sentences that begin 
    # with a small letter ie begin with a gene name!!!
    $line =~ s/\._([a-z]{3,4}-\d+)/\. $1/g;
    # EXCEPTION; unprotect those sentences that end with 
    # a capitalized abreviation, eg RNA!!!
    $line =~ s/ (\w+[A-Z]{2})\._/ $1\. /g;
    
    #rules for journal titles
    # protects abbreviated journal title names!
    $line =~ s/([A-Z]\w+\.) ([A-Z]\w*\.) ?([A-Z]\w*\.)? ?([A-Z]\w*\.)? ?([A-Z]\w*\.)?/$1_$2_$3_$4_$5/g;           
    
    # reintroduce newline characters at ends
    # of sentences only where there
    # is a period followed by a space.
    $line =~ s/(\S\.|\S\?|\S\!) /$1\n/g;
    # modified by HMM previous line to match more cases 
    # for 'reintroduces newlines'
    
    # reverse recognized EOSes
    $line =~ s/_PERIOD_EOS__/ \. \n/g;
    $line =~ s/_QMARK_EOS__/ \? \n/g;
    $line =~ s/_EMARK_EOS__/ \! \n/g;
    

# commented out because too many false positives    
#    # places newline after section titles! 
#    $line =~ s/\b(ABSTRACT|RESEARCH COMMUNICATION|INTRODUCTION|MATERIALS AND METHODS|RESULTS|DISCUSSION|RESULTS AND DISCUSSION|REFERENCES)\b/$1\n/gi;  
    
    # reintroduce spaces following periods that 
    # do not mark the end of a sentence 
    # unprotects any period followed by a space and an small letter
    $line =~ s/\._([a-z])/\. $1/g;
    # unprotects any journal article names
    $line =~ s/([A-Z]\w+\.)_([A-Z]\w*\.)?_?([A-Z]\w*\.)?_?([A-Z]\w*\.)?_?([A-Z]\w*\.)?/$1 $2 $3 $4 $5/g;
    
    # rules for replacing perl metacharacters 
    # and other characters worth keeping
    # with literal descriptions in text ...
    
    # turns " into DQ
    $line =~ s/\"/_DQ__/g;
    # turns < into LT    
    $line =~ s/\</_LT__/g;
    # turns > into GT
    $line =~ s/\>/_GT__/g; 
    # turns + into EQ
    $line =~ s/\=/_EQ__/g;
    # turns & into AND
    $line =~ s/\&/_AND__/g;
    # turns @ into AT
    $line =~ s/\@/_AT__/g; 
    # turns / into SLASH
    $line =~ s/\//_SLASH__/g;
    # turns $ into DOLLAR
    $line =~ s/\$/_DOLLAR__/g;
    # turns % into PERCENT
    $line =~ s/\%/_PERCENT__/g;
    # turns ^ into CARET
    $line =~ s/\^/_CARET__/g;
    # turns * into STAR
    $line =~ s/\*/_STAR__/g;
    # turns + into PLUS
    $line =~ s/\+/_PLUS__/g;
    # turns | into VERTICAL
    $line =~ s/\|/_VERTICAL__/g;
    # turns \ into BACKSLASH
    $line =~ s/\\/_BACKSLASH__/g;

    # including turning all punctuation 
    # into literals .....
    $line =~ s/\./_PERIOD__/g;
    $line =~ s/\?/_QMARK__/g;
    $line =~ s/\!/_EMARK__/g;
    $line =~ s/,/_COMMA__/g;
    $line =~ s/;/_SEMICOLON__/g;
    $line =~ s/:/_COLON__/g;
    $line =~ s/\[/_OPENSB__/g;
    $line =~ s/\]/_CLOSESB__/g;
    $line =~ s/\(/_OPENRB__/g;
    $line =~ s/\)/_CLOSERB__/g;
    $line =~ s/\{/_OPENCB__/g;
    $line =~ s/\}/_CLOSECB__/g;
    $line =~ s/\-/_HYPHEN__/g;
    $line =~ s/\n/_NLC__/g;
    $line =~ s/ /_SPACE__/g;
    
    # now get fid of any non-literal characters...
    
    $line =~ s/\W//g;
    
    # now replace all back ...
    
    $line =~ s/_DQ__/\"/g;
    $line =~ s/_LT__/\</g;	
    $line =~ s/_GT__/\>/g;
    $line =~ s/_EQ__/\=/g;
    $line =~ s/_AND__/\&/g;
    $line =~ s/_AT__/\@/g;
    $line =~ s/_SLASH__/\//g;
    $line =~ s/_DOLLAR__/\$/g;
    $line =~ s/_PERCENT__/\%/g;
    $line =~ s/_CARET__/\^/g;
    $line =~ s/_STAR__/\*/g;
    $line =~ s/_PLUS__/\+/g;
    $line =~ s/_VERTICAL__/\|/g;
    $line =~ s/_BACKSLASH__/\\/g;
    $line =~ s/_PERIOD__/\./g;
    $line =~ s/_QMARK__/\?/g;
    $line =~ s/_EMARK__/\!/g;
    $line =~ s/_COMMA__/,/g;
    $line =~ s/_SEMICOLON__/;/g;
    $line =~ s/_COLON__/:/g;
    $line =~ s/_OPENSB__/\[/g;
    $line =~ s/_CLOSESB__/\]/g;
    $line =~ s/_OPENRB__/\(/g;
    $line =~ s/_CLOSERB__/\)/g;
    $line =~ s/_OPENCB__/\{/g;
    $line =~ s/_CLOSECB__/\}/g;
    $line =~ s/_HYPHEN__/\-/g;
    $line =~ s/_NLC__/\n/g;
    $line =~ s/_SPACE__/ /g;
    
    # rules for tokenizing punctuation marks in text
    # places space around ();:,.[]{}
    $line =~ s/([\)\:\;\,\.\(\[\{\}\]])/ $1 /g;
    
    # finally, clean up any extra spaces####
    # gets rid of tabs
    $line =~ s/\t/ /g;
    # gets rid of extra space              
    $line =~ s/ +/ /g;
    # gets rid of space after newline   
    $line =~ s/\n\s+/\n/g;   
    
    return $line;
    
}

sub SpecialReplacements {
    
    my $line = shift;
    
    # rules for converting abreviations to whole words....
    
    $line =~ s/([\w]+)\'[Ll][Ll]/$1 will/g;          # eg i'll turns into i will
    $line =~ s/([\w]+)\'[Rr][Ee]/$1 are/g;           # eg you're turns into you are
    $line =~ s/([\w]+)\'[Vv][Ee]/$1 have/g;          # eg i've turns into i have
    $line =~ s/ ([Ww])on\'t/ $1ill not/g;            # eg won't turns into will not
    $line =~ s/ ([Dd])on\'t/ $1oes not/g;            # eg don't turns into does not
    $line =~ s/ ([Hh])aven\'t/ $1ave not/g;          # eg haven't turns into have not
    $line =~ s/ ([Cc])an\'t/ $1an not/g;             # eg can't turns into can not
    $line =~ s/ ([Cc])annot/ $1an not/g;             # eg cannot turns into can not
    $line =~ s/ ([Ss])houldn\'t/ $1hould not/g;      # eg shouldn't turns into should not
    $line =~ s/ ([Cc])ouldn\'t/ $1ould not/g;        # eg couldn't turns into could not
    $line =~ s/ ([Ww])ouldn\'t/ $1ould not/g;        # eg wouldn't turns into would not
    $line =~ s/ ([Mm])ayn\'t/ $1ay not/g;            # eg mayn't turns into may not
    $line =~ s/ ([Mm])ightn\'t/ $1ight not/g;        # eg mightn't turns into might not
    $line =~ s/ [Tt]is/ it is/g;                     # eg tis turns into it is
    $line =~ s/ [Tt]was/ it was/g;                   # eg twas turns into it was
    $line =~ s/ (\w+)\'[sS]/ $1 is/g;                # eg it's turns into it is
    $line =~ s/ (\w+)\'[dD]/ $1 would/g;             # eg it'd turns into it would
    $line =~ s/ (\w+)\'[mM]/ $1 am/g;                # eg i'm turns into i am
    
    return $line;
    
}

sub RemovePreprocessingTags {

    my $file = shift;
    
    open (IN, "<$file");
    my $accumulated = "";
    while (my $line = <IN>) {
	$accumulated .= $line;
    }
    close (IN);
    foreach my $item (@{(SY_PREPROCESSING_TAGS)}) {
	$accumulated =~ s/\<$item\S*?\>//g;
	$accumulated =~ s/\<\/$item\>//g;
    }
    open (OUT, ">$file");
    print OUT $accumulated;
    close (OUT);

}

sub HasPreprocessingTags {
    
    my $term = shift;
    my @tags = @_;
    foreach my $tag (@tags) {
	if ($term =~ /^\<$tag\S*?\>\S+?\<\/$tag\>$/) {
	    return 1;
	}
    }
    return 0;
}

sub ProcessPreprocessingTags {
    
    my $term = shift;
    my @tags = @_;
    my @aux = ();
    foreach my $tag (@tags) {
	my @aux2 = $term =~ /^\<$tag\_(\S*?)\>(\S+?)\<\/$tag\>$/;
	@aux = (@aux, @aux2);
    }
    my %retaux = ();
    while (@aux) {
	my $attstring = shift(@aux);
	if ($attstring =~ /\=yes/) {
	    (my $cat) = $attstring =~ /(\S+?)\=yes/;
	    $retaux{$cat} = shift(@aux);
	}
    }
    return %retaux;
}

1;
