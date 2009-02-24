package TextpressoGeneralGlobals;

# Package provides global constants for
# various matters related to Textpresso that are
# used throughout the system.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena.

use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(GE_DELIMITERS);

use constant GE_DELIMITERS => { lexicon => '#####',
				start_annotation => '## BOA ##',
				end_annotation => '## EOA ##',
				start_sentence_left => '### s',
				start_sentence_right => ' ###',
				end_sentence => '### EOS ###',
				parent_category => '## PARENTCATEGORY ##',
				annotation_entry_left => '\s|-|^',
				annotation_entry_right => '\s|-|$',
				keyword_entry => '\.\;\,\:\s\(\)\[\]\{\}',
				word => ' -'};
        
1;
