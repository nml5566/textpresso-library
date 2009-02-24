package TextpressoDisplayGlobals;

# Package provides global constants for all
# Webdisplay related matters of the Textpresso
# system.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena.

use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(DSP_BGCOLOR DSP_TXTCOLOR DSP_LNKCOLOR DSP_AUTHOR DSP_HDRBCKGRND DSP_HDRFACE DSP_HDRSIZE DSP_HDRCOLOR DSP_TXTFACE DSP_TXTSIZE DSP_HIGHLIGHT_COLOR HTML_ROOT HTML_LINKTEMPLATES HTML_MENU HTML_LOGO HTML_NONE HTML_ON HTML_OFF);

use constant DSP_BGCOLOR => 'white';
use constant DSP_TXTCOLOR => 'black';
use constant DSP_LNKCOLOR => '#484d4d';
use constant DSP_AUTHOR => 'Hans-Michael Muller';
use constant DSP_HDRBCKGRND => '#CCCCCC';
use constant DSP_HDRFACE => 'arial, Verdana,sans-serif';
use constant DSP_HDRSIZE => 'small';
use constant DSP_HDRCOLOR => '#414242';
use constant DSP_TXTFACE => 'arial, verdana, helvetica';
use constant DSP_TXTSIZE => 'small';
use constant DSP_HIGHLIGHT_COLOR => {1 => '#53278B',
				     2 => '#25991B',
				     3 => '#7F1300',
				     4 => '#cccccc',
				     5 => '#D27519',
				     6 => '#ffccff',
				     7 => '#696FAC',
				     menutexton => 'black',
				     menutextoff => '#001EC9',
				     bgwhite => '#ffffff',
				     oncolor => '#006400',
				     offcolor => '#8b0000',
				     texthighlight => '#5000A0',
				     warning => '#ff0000'};

# The following constants need adjustments for each implementation
use constant HTML_ROOT => 'http://tetramer.tamu.edu/';

use constant HTML_LINKTEMPLATES => ''; #'/Library/WebServer/WebServer/textpresso/misc/link.templates';

use constant HTML_MENU => { 'Contact Us' => 'cgi-bin/textpresso/feedback',
			    'User Guide' => 'cgi-bin/textpresso/user_guide',
			    'Categories/Ontology' => 'cgi-bin/textpresso/ontology',
			    'Query Language' => 'cgi-bin/textpresso/tql',
			    'Search' => 'cgi-bin/textpresso/search'};

use constant HTML_LOGO => 'textpresso/gif/textpresso_new.jpg';
# end constants that need adjustments

use constant HTML_NONE => 'none';
use constant HTML_ON => 'on';
use constant HTML_OFF => 'off';
1;
