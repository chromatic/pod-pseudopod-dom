#! perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::XHTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse( $file );

like_string $result, qr!<h1>Some Document</h1>!,
    '0 heads should become chapter titles';

like_string $result, qr!<h2>A Heading</h2>!,
    'A heads should become section titles';

like_string $result, qr!<h3>B heading</h3>!,
    'B heads should become subsection titles';

like_string $result, qr!<h4>c heading</h4>!,
    'C heads should become subsubsection titles';

like_string $result, qr/<a name="#AnotherSuppressedHeading">/,
    '... chapter title TOC suppression should create anchor, not heading';

like_string $result, qr/<a name="#ASuppressedHeading">/,
    '... section TOC suppression should work';

like_string $result, qr/<a name="#YetAnotherSuppressedHeading">/,
    '... subsection TOC suppression should work';

like_string $result,
    qr/<pre><code>\s*&quot;This text.+--.+ \$text.&quot;\n/s,
    'programlistings should become unescaped, verbatim result';

like_string $result,
    qr!<pre><code>\s*This should also be \$unm0d\+ified</code>!s,
    'screens should become unescaped, verbatim result';

like_string $result,
    qr/class="blockquote">\s*<p>Blockquoted text.+&quot;escaped&quot;\./,
    'blockquoted text gets escaped';

like_string $result, qr!<ul>\s*<li>Verbatim</li>!s,
    'text-item lists need description formatting to start';

like_string $result, qr!<li>items</li>\s*</ul>!,
    '... and to end';

like_string $result, qr!rule too:</p>\s*<ul>!s;

like_string $result, qr!<ul>\s*<li>BANG</li>!s,
    'bulleted lists need itemized formatting to start';

like_string $result, qr|<li>BANGERANG!</li>\s*</ul>|,
    '... and to end';

like_string $result,
    qr!<ul>\s*<li><p>wakawaka</p>\s*<p>What Pac-Man says.</p>\s*</li>!s,
    'definition lists need description formatting to start';

like_string $result,
    qr!<li><p>ook ook</p>\s*<p>What.+says\.</p>\s*</li>\s*</ul>!,
    '... and to end';

like_string $result,
    qr!<div class="literal"><p>Here are several paragraphs.</p>!s,
    'literal sections should work';

like_string $result,
    qr!<p>They should have <em>newlines</em> in between them\.</p>!s,
    '... even with subelements of paragraphs';

like_string $result, qr!them\.</p>\s*<p></p>!,
    '... even with extra embedded newlines';

TODO:
{
    local $TODO = "Seems like an upstream bug here\n";

    like_string $result, qr/\\begin{enumerate}.+\\item \[2\] First/,
        'enumerated lists need their numbers intact';

    like_string $result, qr/\\item \[77\].+Fooled you!.+\\end{itemize}/s,
        '... and their itemized endings okay';
}

done_testing;
