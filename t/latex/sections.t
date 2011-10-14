#! perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t latex test_file.pod ) ) );
my $result = parse( $file );

like_string $result, qr/\\chapter{Some Document}/,
    '0 heads should become chapter titles';

like_string $result, qr/\\section{A Heading}/,
    'A heads should become section titles';

like_string $result, qr/\\subsection{B heading}/,
    'B heads should become subsection titles';

like_string $result, qr/\\subsubsection{c heading}/,
    'C heads should become subsubsection titles';

like_string $result, qr/\\chapter\*{Another Suppressed Heading}/,
    '... chapter title TOC suppression should work';

like_string $result, qr/\\section\*{A Suppressed Heading}/,
    '... section TOC suppression should work';

like_string $result, qr/\\subsection\*{Yet Another Suppressed Heading}/,
    '... subsection TOC suppression should work';

like_string $result,
    qr/\\begin{Verbatim}.+"This text.+--.+\$text."\n\\end{Verbatim}/s,
    'programlistings should become unescaped, verbatim result';

like_string $result,
    qr/\\begin{Verbatim}.*label=.+This should also be \$unm0d\+ified\n\\end{V/s,
    'screens should become unescaped, verbatim result';

like_string $result, qr/Blockquoted text.+``escaped''\./,
    'blockquoted text gets escaped';

like_string $result, qr/\\begin{description}.+\\item\[\] Verbatim\n\n/s,
    'text-item lists need description formatting to start';

like_string $result, qr/\\item\[\] items\n\n\\end{description}/,
    '... and to end';

like_string $result, qr/rule too:\n\n.+?\\begin/s;

like_string $result, qr/\\begin{itemize}.+?\\item BANG..\\item/s,
    'bulleted lists need itemized formatting to start';

like_string $result, qr/\\item BANGERANG!\n\n\\end{itemize}/,
    '... and to end';

like_string $result,
    qr/\\begin{description}.+?\\item\[\] wakawaka.+?What/s,
    'definition lists need description formatting to start';

like_string $result,
    qr/\\item\[\] ook ook\n\nWhat.+says\.\n\n\\end{description}/,
    '... and to end';

TODO:
{
    local $TODO = "Seems like an upstream bug here\n";

    like_string $result, qr/\\begin{enumerate}.+\\item \[2\] First/,
        'enumerated lists need their numbers intact';

    like_string $result, qr/\\item \[77\].+Fooled you!.+\\end{itemize}/s,
        '... and their itemized endings okay';
}

done_testing;
