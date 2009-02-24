package TextpressoGeneralTasks;

# Package provide class and methods for
# tasks related to processing and maintaining
# the Textpresso system. These are routines
# that are used throughout the system.
#
# (c) 2005 Hans-Michael Muller, Caltech, Pasadena.

use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ReadLexica FindRelevantEntries GetLines GetStopWords ascending descending);

sub GetLines {
    
    my $plainfile = shift;
    my $chomped = shift;
    my @lines = ();
    
    open (PLAIN, "$plainfile") || return @lines;
    
    while (my $line = <PLAIN>) {
	if ($chomped) {
	    chomp($line);
	}
        push @lines, $line;
    }
    close (PLAIN);
    return @lines;
    
}

sub GetStopWords {
    
    my $stopwordfile = shift;
    my %stopwords = ();
    open (IN, "<$stopwordfile") || return %stopwords;
    while (my $line = <IN>) {
	chomp ($line);
	$line =~ s/\s+//g;
	$stopwords{$line} = 1;
    }
    close (IN);
    return %stopwords;
    
}

sub ReadLexica {
    
    use File::Basename;
    
    my $dirin = shift;
    my $del = shift;
    my %lexicon = ();
    
    my @lexfiles = <$dirin/*>;
    
    foreach my $file (@lexfiles) {
	(my $fname, my $fdir, my $fsuf) = fileparse($file, qr{\.\d+-gram});
	$fsuf =~ s/^\.(\d+)-gram/$1/;
	open (IN, "<$file");
	my $inline = '';
	while (my $line = <IN>) {
	    $inline .= $line;
	}
	my @entries = split (/$del\n/, $inline);
	foreach my $entry (@entries) {
	    my @items = split (/\n/, $entry);
	    my $ukey = shift(@items);
	    @{$lexicon{$ukey}{$fname}} = @items;
	}
	close (IN);
    }
    return %lexicon;
}

sub FindRelevantEntries {
    
    my $line = shift;
    my $pLexicon = shift;
    my %list = ();
    
    foreach my $phrase (keys % { $pLexicon }) {
	foreach my $category (keys % { $$pLexicon{$phrase} }) {
	    if ($line =~ m/$phrase/) {
		$list{$phrase}{$category} = 1;
	    }
	}
    }
    
    return %list;
}

sub ascending {  $a <=> $b }
sub descending {  $b <=> $a }

1;
