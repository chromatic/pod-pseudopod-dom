use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse_with_anchors( $file );

like_string $result,
    qr/&quot;This text should not be escaped -- it is normal \$text\.&quot;/,
    'verbatim sections should be unescaped';

like_string $result,
    qr|#!/bin/perl does need escaping, but not \\ \(back|,
    '... including a few metacharacters';

like_string $result, qr/-- it is also &quot;normal&quot;.+\$text./s,
    '... indented too';

like_string $result, qr/octothorpe, #/,              '# needs no quoting';
like_string $result, qr/ \$/,                        '$ needs no quoting';

like_string $result, qr/&amp;/,                      '& should get quoted';
like_string $result, qr/ %/,                         '% needs no quoting';
like_string $result, qr/ _\./,                       '_ needs no quoting';
like_string $result, qr/ ~/,                         '~ needs no quoting';
like_string $result, qr/caret \^/,                   '^ needs no quoting';

like_string $result, qr/escaping: \\\./,             '\ needs no quoting';
like_string $result, qr/\{\},/,                      '{ and } need no quoting';

like_string $result, qr/&quot;The interesting/,
    'starting double quotes should get escaped into entity';

like_string $result, qr/, &quot;they turn/, '... even inside a paragraph';

like_string $result, qr/quotes,&quot; he said,/,
    'ending double quotes should get escaped into entity';

like_string $result, qr/ direction\.&quot;/,
    '... also at the end of a paragraph';

like_string $result, qr/ellipsis\.\.\. and/, 'ellipsis needs no translation';

like_string $result, qr/flame/, 'fl ligature gets no marking';

like_string $result, qr/filk/, 'fi ligature also gets no marking';

like_string $result, qr/ineffable/, 'ff ligature also gets no marking';

like_string $result, qr/ligatures&mdash;and/,
    'spacey double dash should become a real emdash';

like_string $result, qr/<a name="negation%21operator1">/,
    '! needs URI encoding in index anchor';

like_string $result, qr/<a name="array%40sigil1">/,
    '@ needs URI encoding in index anchor';

like_string $result, qr/<a name="thepipe|1">/,
    'spaces removed from index anchors';

like_string $result, qr/<a name="strangequoteaa1">/,
    'quotes removed from index anchors';

like_string $result, qr/<a name="%24%5EW%3Bcarats1">/,
    '... carat needs URI encoding in anchor';

like_string $result, qr/<a name="hierarchicalterms%3Bomittingtrailingspaces1">/,
    'trailing spaces in hierarchical terms should be ignored';

like_string $result, qr/<a name="codeanditalicstext1">/,
    '... and code/italics formatting';

like_string $result, qr/<a name="%3C%3D%3E%3Bnumericcomparisonoperator1">/,
    '... and should escape <> symbols';

like_string $result, qr/<a name="sigils%3B%261">/,
    '... in index anchors as well';

like_string $result, qr/<a name="\.tfiles1">/,
    '... and should suppress HTML tags in index anchors';

like_string $result, qr/<a name="operators%3B&lt;1">/,
    '... encoding entities as necessary';

like_string $result, qr/<code>&lt;=&gt;<\/code>/,
    '... even when specified as characters';

like_string $result, qr/<li>\$BANG BANG\$<p>/,
    'escapes work inside items first line';

like_string $result, qr/And they _ are \$ properly \% escaped/,
    'escapes work inside items paragraphs';

like_string $result, qr/has_method/, 'no need to escape _';

like_string $result, qr/add_method/, '... anywhere';

done_testing;
