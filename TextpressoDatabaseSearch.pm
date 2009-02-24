package TextpressoDatabaseSearch;

# Package provides class and methods for
# database searches in the Textpresso
# system.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena.

use TextpressoDatabaseGlobals;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(textpressosearch littgtkey getstopwords readresults saveresults dobooleanand dobooleanor dobooleannot);

sub textpressosearch {
    
    my $query = shift; # pointer to a TextpressDatabaseQuery object;
    my $newsearch = shift;
    my $searchfn = shift;
    my $searchmode = shift;
    my @subresults = ();
    
    my %final = ();
    if ($newsearch) {
	# do actual search
	for (my $i = 0; $i < $query->numberofconditions; $i++) {
	    foreach my $lit ($query->literatures($i)) {
		foreach my $trgt ($query->targets($i)) {
		    my %aux = retrievesubresult($lit, $query->type($i), 
						$trgt, $query->data($i),
						$query->exactmatch($i),
						$query->casesensitive($i),
						$query->occurrence($i),
						$query->comparison($i),
						$searchmode);
		    foreach my $key (keys % { $aux{$lit} })  {
			foreach my $sen (keys % { $aux{$lit}{$key}{$trgt} }) {
			    $subresults[$i]{$lit}{$key}{$trgt}{$sen} +=
				$aux{$lit}{$key}{$trgt}{$sen};
			}
		    }
		}
	    }
	}
	%final = processindexhashes($query, \@subresults) if (@subresults);
	saveresults(\%final, $searchfn);
    } else {
	# just read in from file
	%final = readresults($searchfn);
    }
    return %final;


}

sub retrievesubresult {

    my $literature = shift;
    my $type = shift;
    my $target = shift;
    my $data = shift;
    my $exactmatch = shift;
    my $casesensitive = shift;
    my $occ = shift;
    my $comp = shift;
    my $searchmode = shift;

    my %result = ();
    my $name = DB_ROOT . '/' . (DB_LITERATURE)->{$literature} . '/' . 
	DB_INDEX . '/' . (DB_SEARCH_TARGETS)->{$target} . (DB_SEARCH_FLAVOR)->{$type} . '/';
    my @dataitems = split (/\,/, $data);
    foreach my $item (@dataitems) {
	if (($type eq 'category') || ($type eq 'attribute')) {
	    my $nm = $name . $item;
	    readindexfile($literature, $type, $target, $nm, \%result,
			  scalefactor($literature, $target, $nm, $searchmode));
	} elsif ($type eq 'keyword') {
	    my @variations = ();
	    if ($casesensitive) {
		@variations = ($item);
	    } else {
		my @first = (substr($item, 0, 1));
		if ($first[0] =~ /[A-Za-z]/) {
		    if (uc($first[0]) eq $first[0]) {
			push @first, lc($first[0]);
		    } else {
			push @first, uc($first[0]);
		    }
		}
		my @second = (substr($item, 1, 1));
		if ($second[0] =~ /[A-Za-z]/) {
		    if (uc($second[0]) eq $second[0]) {
			push @second, lc($second[0]);
		    } else {
			push @second, uc($second[0]);
		    }
		}
		my %kvars = ();
		foreach my $f (@first) {
		    foreach my $s (@second) {
			my $dir = $name . $f . "/" . $s . "/";
			my $dirlist = join (" ", glob("$dir*"));
			$dirlist =~ s/$dir//g;
			while ($dirlist =~ /(\s|^)($item)/gi) {
			    $kvars{$2} = 1;
			}
		    }
		}
		@variations = keys % kvars;	    
	    }
	    foreach my $var (@variations) {
		my $sd1 = substr($var, 0, 1);
		my $sd2 = substr($var, 1, 1);
		my $nm = $name . $sd1 . '/' . $sd2 . '/' . $var;
		if (!$exactmatch) {
		    $nm .= '*';
		}
		readindexfile($literature, $type, $target, $nm, \%result,
			      scalefactor($literature, $target, $nm, $searchmode));
	    }
	}
    }
    
    # normalize %result if searchmode is 'vector';
    if ($searchmode =~ /vector/i) {
	foreach my $lit (keys % result) {
	    foreach my $key (keys % { $result{$lit} }) {
		foreach my $tgt (keys % { $result{$lit}{$key} }) {
		    my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$lit} . '/' . 
			DB_TEXT . '/' . (DB_SEARCH_TARGETS)->{$tgt} . '/' . $key;
		    my ($dm, $dm, $dm, $dm, $dm, $dm, $dm, $size,
			$dm, $dm, $dm, $dm, $dm) = stat($fn);
		    foreach my $sen (keys % { $result{$lit}{$key}{$tgt} }) {
			$result{$lit}{$key}{$tgt}{$sen} /= log(1.01 + $size/100);
		    }
		}
	    }
	}
    }

    foreach my $lit (keys % result) {
	foreach my $key (keys % { $result{$lit} }) {
	    foreach my $tgt (keys % { $result{$lit}{$key} }) {
		foreach my $sen (keys % { $result{$lit}{$key}{$tgt} }) {
		    delete $result{$lit}{$key}{$tgt}{$sen}
		    if (!testnumericalcondition($result{$lit}{$key}{$tgt}{$sen}, $comp, $occ));
		}
	    }
	}
    }

    return cleanresults(\%result);
}

sub readindexfile {
    
    my $literature = shift;
    my $type = shift;
    my $target = shift;
    my $name = shift;
    my $p_result = shift;
    my $scalefactor = shift;

    my @files = glob($name);
    foreach my $file (@files) {
	open (IN, "<$file");
	while (my $line = <IN>) {
	    chomp ($line);
	    my @entry = split(/\,/, $line);
	    my $key = shift (@entry);
	    foreach (@entry) {
		$$p_result{$literature}{$key}{$target}{$_} += $scalefactor;
	    }
	}
	close (IN);
    }
}

sub scalefactor {
    
    my $literature = shift;
    my $target = shift;
    my $indexfilename = shift;
    my $searchmode = shift;
    my $alpha = 1; # value is default for boolean searchmode
    
    if ($searchmode =~ /vector/i) {
        my $fn = DB_ROOT . '/' . (DB_LITERATURE)->{$literature} . '/' .
	    DB_TEXT . '/' . (DB_SEARCH_TARGETS)->{$target} . '/';
	my @aux = glob("$fn*");
	my $totaldocs = scalar(@aux);
	my @files = glob($indexfilename);
	my $docnumbers = 0;
	foreach my $file (@files) {
	    open (IN, "<$file");
	    while (my $line = <IN>) {
		$docnumbers++;
	    }
	    close (IN);
	}
	$alpha *= log($totaldocs/$docnumbers) if ($docnumbers > 0);
    }
    return $alpha;


}

sub processindexhashes { # process booleans, numerical cond. and range

    my $query = shift;
    my $subref = shift;

    my %final = ();
    my $i = 0;
    while ($i < $query->numberofconditions) {
	if ($query->boolean($i) eq '&&') {
	    my %aux = ();
	    if (defined(%{$$subref[$i]})) {
		%aux = %{$$subref[$i]};
	    }
	    my @prevdatas = ($query->data($i));
	    my @prevtypes = ($query->type($i));
	    my $j = $i+1;
	    while ($query->boolean($j) eq '++') {
		push @prevdatas, $query->data($j);
		push @prevtypes, $query->type($j);
		my %aux2 = ();
		if (defined(%{$$subref[$j]})) {
		    %aux2 = %{$$subref[$j]};
		}
		%aux = dobooleanand(\%aux, \%aux2, $query->range($i));
		$j++;
	    }
	    if (@prevdatas > 1) {
		%aux = checknextneighbors(\%aux, \@prevdatas, \@prevtypes, $query->casesensitive);
	    }
	    if ($i > 0) {
		%final = dobooleanand(\%final, \%aux, $query->range($i));
	    } else {
		%final = %aux;
	    }
	} elsif ($query->boolean($i) eq '||') {
	    if ($i > 0) {
		%final = dobooleanor(\%final, $$subref[$i]);
	    } else {
		%final = %{$$subref[$i]};
	    }
	} elsif ($query->boolean($i) eq '!!') {
	    my %aux = ();
	    if (defined(%{$$subref[$i]})) {
		%aux = %{$$subref[$i]};
	    }
	    my @prevdatas = ($query->data($i));
	    my @prevtypes, ($query->type($i));
	    my $j = $i+1;
	    while ($query->boolean($j) eq '--') {
		push @prevdatas, $query->data($j);
		push @prevtypes, $query->type($j);
		my %aux2 = ();
		if (defined(%{$$subref[$j]})) {
		    %aux2 = %{$$subref[$j]};
		}
		%aux =dobooleanand(\%aux, \%aux2, $query->range($i));
		$j++;
	    }
	    if (@prevdatas > 1) {
		%aux = checknextneighbors(\%aux, \@prevdatas, \@prevtypes, $query->casesensitive);
	    } 
	    if ($i > 0) {
		%final = dobooleannot(\%final, \%aux, $query->range($i));
	    } else {
		%final = %aux;
	    }
	}
	$i++;
    }


    return %final;
}

sub checknextneighbors {

    my $pResults = shift;
    my $pDatas = shift;
    my $pTypes = shift;
    my $casesensitive = shift;

    my $prime = shift(@$pTypes);

    # if the types of next neighbor are not identical, then
    # return empty list.
    foreach my $type (@$pTypes) {
	if ($type ne $prime) {
	    return ();
	}
    }

    my %ret = ();
    # check for keyword phrases or category neighbor
    if ($prime eq 'keyword') {
	use TextpressoGeneralTasks;
	my $phrase = join (" ", @$pDatas);
	foreach my $lit (keys % $pResults ) {
	    foreach my $key (keys % { $$pResults{$lit} }) {
		foreach my $tgt (keys % { $$pResults{$lit}{$key} }) {
		    my @sentences = (keys % { $$pResults{$lit}{$key}{$tgt} });
		    if (scalar (@sentences) > 0) {
			my $filename = DB_ROOT . '/' . (DB_LITERATURE)->{$lit} . '/' . 
			    DB_TEXT . '/' . (DB_SEARCH_TARGETS)->{$tgt} . '/' . $key;
			my @lines = GetLines($filename, 1);
			foreach my $sen (@sentences) {
			    (my $j = $sen) =~ s/s//;
			    $j -= 1;
			    if ($casesensitive) {
				if ($lines[$j] =~ /$phrase/) {
				    $ret{$lit}{$key}{$tgt}{$sen} = $$pResults{$lit}{$key}{$tgt}{$sen};
				}
			    } else {
				if ($lines[$j] =~ /$phrase/i) {
				    $ret{$lit}{$key}{$tgt}{$sen} = $$pResults{$lit}{$key}{$tgt}{$sen};
				}
			    }
			    
			}
		    }
		}
	    }
	}
    } elsif ($prime eq 'category') {
	# currently not implemented, but easy to do.
    }
    return %ret;
    

}

sub dobooleannot {

    my $pA = shift;
    my $pB = shift;
    my $range = shift;
    
    foreach my $lit (keys % $pA) {
	foreach my $key (keys % { $$pA{$lit} }) {
	    if ((DB_SEARCH_RANGES)->{$range} eq 'sentence') {
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {
			delete $$pA{$lit}{$key}{$tgt}{$sen} 
			if ($$pB{$lit}{$key}{$tgt}{$sen}> 0.0);
		    }
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'target') {
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    my $factorB = 0.0;
		    foreach my $sen (keys % { $$pB{$lit}{$key}{$tgt} }) {
			$factorB += $$pB{$lit}{$key}{$tgt}{$sen};
		    }
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {
			delete $$pA{$lit}{$key}{$tgt}{$sen} if ($factorB > 0.0);
		    }
		}
	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'document') {
		my $factorB = 0.0;
		foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pB{$lit}{$key}{$tgt} }) {
			$factorB += $$pB{$lit}{$key}{$tgt}{$sen};
		    }
		}
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {
			delete $$pA{$lit}{$key}{$tgt}{$sen} if ($factorB > 0.0);
		    }
		}
	    }
	}
    }
    return cleanresults($pA);


}

sub dobooleanor {
		
    my $pA = shift;
    my $pB = shift;

    foreach my $lit (keys % $pB) {
	foreach my $key (keys % { $$pB{$lit} }) {
	    foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
		foreach my $sen (keys % { $$pB{$lit}{$key}{$tgt} }) {
		    $$pA{$lit}{$key}{$tgt}{$sen} +=
			$$pB{$lit}{$key}{$tgt}{$sen};
		}
	    }
	}
    }
    return %$pA;


}

sub dobooleanand {
    
    my $pA = shift;
    my $pB = shift;
    my $range = shift;

    foreach my $lit (keys % $pA) {
	foreach my $key (keys % { $$pA{$lit} }) {
	    if ((DB_SEARCH_RANGES)->{$range} eq 'sentence') {
	        foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {

			$$pA{$lit}{$key}{$tgt}{$sen} 
			*= $$pB{$lit}{$key}{$tgt}{$sen};
		    }
		}

	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'target') {

		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    my $factorA = 0.0;
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {
			$factorA += $$pA{$lit}{$key}{$tgt}{$sen};
		    }
		    my $factorB = 0.0;
		    foreach my $sen (keys % { $$pB{$lit}{$key}{$tgt} }) {
			$factorB += $$pB{$lit}{$key}{$tgt}{$sen};
		    }
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {
			$$pA{$lit}{$key}{$tgt}{$sen} = $factorA*$factorB;
		    }
		    foreach my $sen (keys % { $$pB{$lit}{$key}{$tgt} }) {
			$$pA{$lit}{$key}{$tgt}{$sen} = $factorA*$factorB;
		    }

		}

	    } elsif ((DB_SEARCH_RANGES)->{$range} eq 'document') {

		my $factorA = 0.0;
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {
			$factorA += $$pA{$lit}{$key}{$tgt}{$sen};
		    }
		}
		my $factorB = 0.0;
		foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pB{$lit}{$key}{$tgt} }) {
			$factorB += $$pB{$lit}{$key}{$tgt}{$sen};
		    }
		}
		foreach my $tgt (keys % { $$pA{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pA{$lit}{$key}{$tgt} }) {
			$$pA{$lit}{$key}{$tgt}{$sen} = $factorA*$factorB;
		    }
		}
		foreach my $tgt (keys % { $$pB{$lit}{$key} }) {
		    foreach my $sen (keys % { $$pB{$lit}{$key}{$tgt} }) {
			$$pA{$lit}{$key}{$tgt}{$sen} = $factorA*$factorB;
		    }
		}

	    }

	}
    }
    return cleanresults($pA);


}

sub cleanresults {

    my $pResults = shift;

    my %final = ();
    foreach my $lit (keys % $pResults) { # clean up empty results
	foreach my $key (keys % { $$pResults{$lit} }) {
	    foreach my $tgt (keys % { $$pResults{$lit}{$key} }) {
		foreach my $sen (keys % { $$pResults{$lit}{$key}{$tgt} }) {
		    my $aux = $$pResults{$lit}{$key}{$tgt}{$sen};
		    $final{$lit}{$key}{$tgt}{$sen} = $aux
			if ($aux > 0.0);
		}
	    }
	}
    }
    return %final;


}

sub testnumericalcondition {

    my $total = shift;
    my $comp = shift;
    my $occ = shift;

    if (($comp eq '>') && ($total > $occ)) {
	return 1;
    } elsif (($comp eq '==') && ($total == $occ)) {
	return 1;
    } elsif (($comp eq '<') && ($total < $occ)) {
	return 1;
    } else {
	return 0;
    }

}

sub sentencediff {

    (my $a = shift) =~ s/s//g;
    (my $b = shift) =~ s/s//g;
    return abs($a-$b);


}

sub sentencewise {

    (my $c = $a) =~ s/s//g;
    (my $d = $b) =~ s/s//g;
    $c <=> $d;

}

sub littgtkey {

    my $input = shift;
    my %output = ();
    foreach my $lit (keys % $input) {
	foreach my $key (keys % { $$input{$lit} }) {
	    foreach my $tgt (keys % { $$input{$lit}{$key} }) {
		foreach my $sen (keys % { $$input{$lit}{$key}{$tgt} }) {
		    push @{$output{"$lit - $tgt - $key"}}, $sen
			if ($$input{$lit}{$key}{$tgt}{$sen} > 0.0);
		}
	    }
	}
    }
    return %output;


}

sub getstopwords {

    my $fn = shift;

    my $endstring = "";
    open (IN, "<$fn");
    while (my $line = <IN>) {
	chomp ($line);
	$line =~ s/\s//g;
	$endstring .= " $line ";
    }
    close (IN);
    return $endstring;


}

sub saveresults {
    
    my $pResults = shift;
    my $fn = shift;
    open (OUT, ">$fn");
    foreach my $lit (keys % $pResults) {
	foreach my $key (keys % { $$pResults{$lit} }) {
	    foreach my $tgt (keys % { $$pResults{$lit}{$key} }) {
		foreach my $sen (keys % { $$pResults{$lit}{$key}{$tgt} }) {
		    print OUT $lit, "\t", $key, "\t", $tgt, "\t", $sen, "\t", $$pResults{$lit}{$key}{$tgt}{$sen}, "\n";
		}
	    }
	}
    }
    close (OUT);
}

sub readresults {

    my $fn = shift;
    my %results = ();
    open (IN, "<$fn");
    while (my $line = <IN>) {
	chomp ($line);
	my @elements = split (/\t/, $line);
	$results{$elements[0]}{$elements[1]}{$elements[2]}{$elements[3]} = $elements[4];
    }
    close (IN);
    return %results;


}

1;
