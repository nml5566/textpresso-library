package TextpressoSystemGlobals;

# Package provides global constants for all
# build related matters of Textpresso.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena.

use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(SY_ROOT SY_SUBROOTS SY_ANNOTATION_TYPE SY_ANNOTATION_SUBTYPE SY_ANNOTATION_SUBTYPE_INSTANCES SY_ANNOTATION_FIELDS SY_PASSTHROUGH_FIELDS SY_SOURCE_FIELDS SY_INDEX_TYPE SY_INDEX_SUBTYPE SY_INDEX_SUBTYPE_INSTANCES SY_INDEX_FIELDS SY_ONTOLOGY SY_SUPPLEMENTALS SY_MAX_NGRAM_SIZE SY_PREPROCESSING_TAGS SY_MARKUP_EXCEPTIONS);

# The following constants need adjustments for each implementation
use constant SY_ROOT => '/usr/local/textpresso/neurospora/Data/';
# end constants that need adjustments

use constant SY_SUBROOTS => { annotations => 'annotations/',
			      includes => 'includes/',
			      excludes => 'excludes/',
			      indices => 'indices/',
			      ontology => 'ontology/',
			      supplementals => 'supplementals/',
			      processedfiles => 'processedfiles/',
			      etc => 'etc/'};

use constant SY_ANNOTATION_FIELDS => { abstract => 'abstract/',
				       body => 'body/',
				       title => 'title/'};

use constant SY_ANNOTATION_TYPE => { grammatical => 'grammatical/',
				     semantic => 'semantic/'};

use constant SY_ANNOTATION_SUBTYPE_INSTANCES => 'semantic';

use constant SY_ANNOTATION_SUBTYPE => { categories => 'categories/',
					attributes => 'attributes/'};

use constant SY_PASSTHROUGH_FIELDS =>  { author => 'author/',
					 accession => 'accession/',
					 citation => 'citation/',
					 journal => 'journal/',
					 type => 'type/',
					 year => 'year/'};

use constant SY_SOURCE_FIELDS => { abstract => 'abstract/',
				   author => 'author/',
				   accession => 'accession/',
				   body => 'body/',
				   citation => 'citation/',
				   journal => 'journal/',
				   title => 'title/',
				   type => 'type/',
				   year => 'year/'};

use constant SY_INDEX_FIELDS => { abstract => 'abstract/',
				  author => 'author/',
				  body => 'body/',
				  title => 'title/',
				  year => 'year/'};

use constant SY_INDEX_TYPE => { grammatical => 'grammatical/',
				semantic => 'semantic/',
				keyword => 'keyword/'};

use constant SY_INDEX_SUBTYPE_INSTANCES => 'semantic';

use constant SY_INDEX_SUBTYPE => { categories => 'categories/',
				   attributes => 'attributes/'};

use constant SY_ONTOLOGY => { definitions => 'definitions/',
			      lexica => 'lexica/'};

use constant SY_SUPPLEMENTALS => { endnote => 'endnote/',
				   keyword => 'keyword/',
				   onlinetext => 'onlinetext/',
				   relatedarticle => 'relatedarticle/'};

use constant SY_SUPPLEMENTALS_DOCS => 'endnote onlinetext relatedarticle';

use constant SY_SUPPLEMENTALS_CONT => 'keyword';

use constant SY_PREPROCESSING_TAGS => ['WSD', 'HTML_ITALICS'];

use constant SY_MARKUP_EXCEPTIONS => ['gene_dmelanogaster'];

use constant SY_MAX_NGRAM_SIZE => 15;

1;
