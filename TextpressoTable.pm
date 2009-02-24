package TextpressoTable;

use strict;

# Package provides class and methods for
# Textpresso-style tables.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena.

# Data elements are:
#
# $self->{rowcounter}
# @{$self->{row}}
# $self->{caption}
#
# First row is considered to be the header. Leave empty if you don't want one.

# default constructor method
sub new {

    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { @_ };
    bless ($self, $class);
    return $self;

}

sub init {

    my $self = shift;
    $self->{rowcounter} = 0;
    @{$self->{row}} = ();
    return 0;

}

sub nextrow {

    my $self = shift;
    $self->{rowcounter}++;

}

sub setelement {

    my $self = shift;
    my $rownumber = shift;
    my $colnumber = shift;
    my $content = shift;
    $self->{row}[$rownumber][$colnumber] = $content;

}

sub addtablerow {

    my $self = shift;
    while (@_) {
	$self->addtableelement(shift);
    }
    $self->nextrow;

}

sub addtableelement {

    my $self = shift;
    push @{$self->{row}[$self->{rowcounter}]}, shift;

}

sub setcaption {

    my $self = shift;
    my $content = shift;
    $self->{caption} = $content;

}

sub maketable {

    use TextpressoDisplayGlobals;

    my $retstr;

    my $self = shift;          # invocant
    my $q = shift;             # query pointer
    my %options = @_;
    my $tablestyle = $options{tablestyle};    # 4 styles available: 
                                              # "borderless", 
                                              # "headerbackground", 
                                              # "normal",
                                              # "borderless-headerbackground"

    my $headerbckgrnd = $options{DSP_BGCOLOR} || DSP_BGCOLOR; 
                                               # change according to style;
                                               # style 'normal' is default
    my $border = defined($options{border}) ? $options{border} : 2;
    my $padding = defined($options{cellpadding}) ? $options{cellpadding} : 2;
    my $spacing = defined($options{cellspacing}) ? $options{cellspacing} : 2;
    my $width = defined($options{width}) ? $options{width} : '';

    if ($tablestyle eq "headerbackground") {
	$headerbckgrnd = $options{DSP_HDRBCKGRND} || DSP_HDRBCKGRND;
    } elsif ($tablestyle eq "borderless") {
	$border = 0;
    } elsif ($tablestyle eq "borderless-headerbackground") {
	$headerbckgrnd = $options{DSP_HDRBCKGRND} || DSP_HDRBCKGRND;
	$border = 0;
    } elsif ($tablestyle eq "seamless") {
	$headerbckgrnd = $options{DSP_HDRBCKGRND} || DSP_HDRBCKGRND;
	$border = 0;
	$padding = 0;
	$spacing = 0;
    }

    my @aux = ();
    my $clr = $options{DSP_HDRCOLOR} || DSP_HDRCOLOR;
    my $sze = $options{DSP_HDRSIZE} || DSP_HDRSIZE;
    my $fce = $options{DSP_HDRFACE} || DSP_HDRFACE;
    foreach my $aux (@{$self->{row}[0]}) {
	push @aux, $q->span({-style => "color:$clr;font-size:$sze;font-family:$fce;"}, $aux);
    }
    my $th = $q->th({-bgcolor => $headerbckgrnd}, 
		    [@aux]) if (defined(@aux));
    my @tds = ();
    $clr = $options{DSP_TXTCOLOR} || DSP_TXTCOLOR;
    $sze = $options{DSP_TXTSIZE} || DSP_TXTSIZE;
    $fce = $options{DSP_TXTFACE} || DSP_TXTFACE;
    for my $i (1 .. $#{$self->{row}}) {
	my @aux = ();
	foreach my $aux (@{$self->{row}[$i]}) {
	    push @aux, $q->span({-style => "color:$clr;font-size:$sze;font-family:$fce;"}, $aux);
	}
	push @tds, $q->td({-bgcolor => $options{DSP_BGCOLOR} || DSP_BGCOLOR},
			  [@aux]) if (defined(@aux));
    }
    
    if (@tds || $th) {
	$retstr = $q->table({-border => $border, 
			     -cellpadding => $padding,
			     -cellspacing => $spacing,
			     -width => $width},
			     $q->caption($q->b($self->{caption})),
			     $q->Tr({-align => $options{align} || 'left', valign => $options{valign} || 'top' },
				   [$th, @tds]));
    }

    return $retstr;
}

1;
