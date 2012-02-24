use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::XHTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file                 = read_file( catfile( qw( t test_file.pod ) ) );
my ($doc, $result, $idx) = parse_with_anchors( $file, filename => 'idx.html' );
my $index                = $doc->emit_full_index( $idx );

like $index, qr/Special formatting /,
    'index should include literal text of index entries';
like $index,
    qr!Special formatting \[<a href="idx.html#Specialformatting1">1</a>\]!,
    '... with hyperlink to text location';
like $index,
    qr!#Specialformatting1">1</a>\] \[<a href="idx.html#Specialformatting2">2!,
    '... for each location';

done_testing;
