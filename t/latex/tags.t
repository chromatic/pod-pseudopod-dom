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

like_string $result, qr!\\label{startofdocument}!,
    'Z<> tags should become labels';

like_string $result, qr!\\label{next_heading}!, '... without normal escaping';

like_string $result, qr!\\label{slightly-complex-heading}!,
    '... and escaping non-alphanumerics';

done_testing;
