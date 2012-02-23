use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::XHTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file           = read_file( catfile( qw( t test_file.pod ) ) );
my ($doc, $result) = parse_with_anchors( $file, filename => 'html_toc.html' );
my $toc            = $doc->emit_toc;

like   $toc, qr/Some Document/, 'TOC should contain chapter heading';
like   $toc, qr!<a href="html_toc.html#SomeDocument">Some Document</a>!,
    '... with link to chapter heading anchor';

like   $toc, qr/A Heading/, 'TOC should contain section heading';
like   $toc, qr!<a href="html_toc.html#AHeading">A Heading</a>!,
    '... with link to section heading anchor';

like   $toc, qr/B heading/, 'TOC should contain sub-section heading';
like   $toc, qr!<a href="html_toc.html#Bheading">B heading</a>!,
    '... with link to sub-section heading anchor';

like   $toc, qr/c heading/, 'TOC should contain sub-sub-section heading';
like   $toc, qr!<a href="html_toc.html#cheading">c heading</a>!,
    '... with link to sub-sub-section heading anchor';

unlike $toc, qr/Another Suppressed Heading/,
    'TOC should lack suppressed chapter heading';
unlike $toc, qr/A Suppressed Heading/,
    'TOC should lack suppressed section heading';
unlike $toc, qr/Yet Another Suppressed Heading/,
    'TOC should lack suppressed sub-section heading';

done_testing;
