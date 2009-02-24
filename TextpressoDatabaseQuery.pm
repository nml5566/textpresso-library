package TextpressoDatabaseQuery;

use strict;

# Package provides class and methods for
# query data objects.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena.

# Data elements
#
# @{$self->{boolean}} # concatenation operator with preceding item
#                     # && and, || or, !! and not, 
#                     # ++ and (is part of phrase, items have to be in
#                     # sequential order)
#                     # -- and not (is part of phrase, items have to be in
#                     # sequential order)
# @{$self->{type}} # one of the DB_SEARCH_FLAVOR
# @{$self->{data}} # actual data item
# @{$self->{occurrence}} # number of required occurrences
# @{$self->{comparison}} # comparison orperator for required occurrences 
# @{$self->{range}} # sentence range
# @{$self->{exactmatch}} # keyword is required as an exact match
# @{$self->{casesensitive}} # keyword is case sensitive
# @{$self->{literature}{(keys % {(DB_LITERATURE)})}} # which literature is to 
                                                     # be searched; not 
                                                     # mutually exclusive
# @{$self->{targets}{(keys % {(DB_SEARCH_TARGETS)})}} # which text is to 
                                                      # be searched; not 
                                                      # mutually exclusive

sub new {

    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = { @_ };
    bless ($self, $class);
    return $self;

}

sub init {
    
    my $self = shift;
    @{$self->{boolean}} = ();
    @{$self->{type}} = ();
    @{$self->{data}} = ();
    @{$self->{occurrence}} = ();
    @{$self->{comparison}} = ();
    @{$self->{range}} = ();
    @{$self->{exactmatch}} = ();
    @{$self->{casesensitive}} = ();
    @{$self->{literature}} = ();
    @{$self->{targets}} = ();
    return 0;

}

sub removelast {
    
    my $self = shift;
    pop @{$self->{boolean}};
    pop @{$self->{type}};
    my $rt = pop @{$self->{data}};
    pop @{$self->{occurrence}};
    pop @{$self->{comparison}};
    return $rt;
    
}

sub removespecific {

    my $self = shift;
    my $i = shift;
    delete $self->{boolean}[$i];
    delete $self->{type}[$i];
    delete $self->{data}[$i];
    delete $self->{occurrence}[$i];
    delete $self->{comparison}[$i];

}

sub addsimple {

    my $self = shift;
    push @{$self->{boolean}}, '&&';
    push @{$self->{type}}, shift;
    push @{$self->{data}}, shift;
    push @{$self->{occurrence}}, 0;
    push @{$self->{comparison}}, '>';
    push @{$self->{range}}, shift;
    push @{$self->{exactmatch}}, shift;
    push @{$self->{casesensitive}}, shift;
    push @{$self->{literature}}, shift;
    push @{$self->{targets}}, shift ;

}

sub addspecific {

    my $self = shift;
    push @{$self->{boolean}}, shift;
    push @{$self->{type}}, shift;
    push @{$self->{data}}, shift;
    push @{$self->{occurrence}}, shift;
    push @{$self->{comparison}}, shift;
    push @{$self->{range}}, shift;
    push @{$self->{exactmatch}}, shift;
    push @{$self->{casesensitive}}, shift;
    push @{$self->{literature}}, shift;
    push @{$self->{targets}}, shift;

}
    
              # all set... routine below not really required,
sub settype { # just in case one wants to manipulate specific fields.
              
    my $self = shift;
    my $i = shift;
    $self->{type}[$i] = shift;

}

sub setdata {

    my $self = shift;
    my $i = shift;
    $self->{data}[$i] = shift;

}

sub setoccurrence {

    my $self = shift;
    my $i = shift;
    $self->{occurrence}[$i] = shift;

}

sub setcomparison {

    my $self = shift;
    my $i = shift;
    $self->{comparison}[$i] = shift;

}

sub setrange {

    my $self = shift;
    my $i = shift;
    $self->{range}[$i] = shift;

}

sub setexactmatch {

    my $self = shift;
    my $i = shift;
    $self->{exactmatch}[$i] = shift; # 0 or 1

}
sub setcasesensitive {

    my $self = shift;
    my $i = shift;
    $self->{casesensitive}[$i] = shift; # 0 or 1

}

sub setliterature {

    my $self = shift;
    my $i = shift;
    my $litref = shift;
    foreach (keys % $litref) {
	$self->{literature}[$i]{$_} = $$litref{$_};
    }

}

sub settargets {

    my $self = shift;
    my $i = shift;
    my $targetsref = shift;
    foreach (keys % $targetsref) {
	$self->{targets}[$i]{$_} = $$targetsref{$_};
    }

}

sub numberofconditions {

    my $self = shift;
    return scalar @{$self->{data}};

}

sub literatures {
    
    my $self = shift;
    my $i = shift;
    my @aux = ();
    foreach my $key (keys % {$self->{literature}[$i]}) {
	push @aux, $key if ($self->{literature}[$i]{$key});
    }
    return @aux;

}

sub targets {

    my $self = shift;
    my $i = shift;
    my @aux = ();
    foreach my $key (keys % {$self->{targets}[$i]}) {
	push @aux, $key if ($self->{targets}[$i]{$key});
    }
    return @aux;
}

sub range {

    my $self = shift;
    my $i = shift;
    return $self->{range}[$i];

}

sub exactmatch {

    my $self = shift;
    my $i = shift;
    return $self->{exactmatch}[$i];

}

sub casesensitive {

    my $self = shift;
    my $i = shift;
    return $self->{casesensitive}[$i];

}

sub boolean {

    my $self = shift;
    my $i = shift;
    return $self->{boolean}[$i];

}

sub type {

    my $self = shift;
    my $i = shift;
    return $self->{type}[$i];

}

sub data {

    my $self = shift;
    my $i = shift;
    return $self->{data}[$i];

}

sub occurrence {

    my $self = shift;
    my $i = shift;
    return $self->{occurrence}[$i];

}

sub comparison {

    my $self = shift;
    my $i = shift;
    return $self->{comparison}[$i];

}

sub savetofile {

    my $self = shift;
    my $filename = shift;

    open (OUT, ">$filename");
    print OUT join("\t", @{$self->{boolean}}), "\n";
    print OUT join("\t", @{$self->{type}}), "\n";
    print OUT join("\t", @{$self->{data}}), "\n";
    print OUT join("\t", @{$self->{occurrence}}), "\n";
    print OUT join("\t", @{$self->{comparison}}), "\n";
    print OUT join("\t", @{$self->{range}}), "\n";
    print OUT join("\t", @{$self->{exactmatch}}), "\n";
    print OUT join("\t", @{$self->{casesensitive}}), "\n";
    foreach my $var ("literature", "targets") {
	for (my $i = 0; $i < @{$self->{$var}}; $i++) {
	    foreach my $lit (keys %{$self->{$var}[$i]}) {
		print OUT $var, "\t", $i, "\t", $lit, "\n";
	    }
	}
    }
    close (OUT);

}

sub readfromfile {

    my $self = shift;
    my $filename = shift;

    open (IN, "<$filename");
    my $aux = <IN>;
    chomp($aux);
    @{$self->{boolean}} = split(/\t/, $aux);
    $aux = <IN>;
    chomp($aux);
    @{$self->{type}} = split(/\t/, $aux);
    $aux = <IN>;
    chomp($aux);
    @{$self->{data}} = split(/\t/, $aux);
    $aux = <IN>;
    chomp($aux);
    @{$self->{occurrence}} = split(/\t/, $aux);
    $aux = <IN>;
    chomp($aux);
    @{$self->{comparison}} = split(/\t/, $aux);
    $aux = <IN>;
    chomp($aux);
    @{$self->{range}} = split(/\t/, $aux);
    $aux = <IN>;
    chomp($aux);
    @{$self->{exactmatch}} = split(/\t/, $aux);
    $aux = <IN>;
    chomp($aux);
    @{$self->{casesensitive}} = split(/\t/, $aux);
    while ($aux = <IN>) {
	chomp($aux);
	my ($var, $i, $lit) = split(/\t/, $aux);
	$self->{$var}[$i]{$lit} = 1;
    }
    close(IN);

}

1;
