package TextpressoDatabaseGlobals;

# Package provides global constants for all
# database related matters of the Textpresso
# system.
#
# (c) 2007 Hans-Michael Muller, Caltech, Pasadena.

use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(DB_ROOT DB_TMP DB_STOPWORDS DB_LITERATURE DB_LITERATURE_DEFAULTS DB_SEARCH_MODE DB_SEARCH_MODE_DEFAULT DB_INDEX DB_TEXT DB_ANNOTATION DB_SEARCH_FLAVOR DB_SEARCH_RANGES DB_SEARCH_RANGES_DEFAULT DB_IS_BIBLIOGRAPHY DB_IS_TEXT DB_SEARCH_TARGETS DB_SEARCH_TARGETS_DEFAULTS DB_DISPLAY_FIELDS DB_MISCELLANEOUS DB_SUPPLEMENTAL DB_OUTLINKS DB_LINKLISTS);

# The following constants need adjustments for each implementation
use constant DB_ROOT => '/Library/WebServer/WebServer/textpresso/tdb/';
use constant DB_TMP => '';
use constant DB_STOPWORDS => '/Library/WebServer/WebServer/textpresso/misc/stopwords';
# end constants that need adjustments

use constant DB_LITERATURE => {	'ecoli' => 'ecoli/', 'neurospora' => 'neurospora/'};

use constant DB_LITERATURE_DEFAULTS => ['ecoli'];#, 'neurospora'];

use constant DB_SEARCH_MODE => ['boolean', 'vector (tf*idf)', 'latent themes'];

use constant DB_SEARCH_MODE_DEFAULT => 'boolean';

use constant DB_INDEX => 'ind/';

use constant DB_TEXT => 'txt/';

use constant DB_ANNOTATION => 'ann/';

use constant DB_SEARCH_FLAVOR => { keyword => 'keyword/',
				   category => 'semantic/categories/',
				   attribute => 'semantic/attributes/'};

use constant DB_SEARCH_RANGES => { sentence => 'sentence',
				   field => 'target',
				   document => 'document'};

use constant DB_SEARCH_RANGES_DEFAULT => 'sentence';


use constant DB_IS_BIBLIOGRAPHY => 'author citation journal type year';

use constant DB_IS_TEXT => 'abstract body title';

use constant DB_SEARCH_TARGETS => { author => 'author/',
				    year => 'year/',
				    abstract => 'abstract/',
				    body => 'body/',
				    mesh => 'mesh/',
				    journal => 'journal/',
				    type => 'type/',
				    pmid => 'accession/',
				    title => 'title/'};

use constant DB_DISPLAY_FIELDS => { author => 'author/',
				    accession => 'accession/',
				    citation => 'citation/',
				    journal => 'journal/',
				    type => 'type/',
				    year => 'year/',
				    abstract => 'abstract/',
				    title => 'title/',
				    mesh => 'mesh/'};



use constant DB_SEARCH_TARGETS_DEFAULTS => ['abstract', 'body', 'title'];

use constant DB_MISCELLANEOUS => { scripts => 'scr/',
				   temporary => 'tmp/'};

use constant DB_SUPPLEMENTAL => { endnote_noabstract => 'end/',
				  endnote_abstract => 'eab/',
				  lexicon => 'lex/',
				  pdfs => 'pdf/'};

use constant DB_OUTLINKS => { related_articles => 'rel/',
			      full_text_links => 'url/',
			      wormbase_links => 'wbl/'};

use constant DB_LINKLISTS => { wormbase_links => 'wbl/'};

1;
