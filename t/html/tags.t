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

like_string $result, qr!^<a name="startofdocument"></a>!m,
    'Z<> tags should become anchors';

like_string $result, qr!^<a name="next_heading"></a>!m,
    '... without normal escaping';

like_string $result, qr!<a name="slightlycomplex\?heading"></a>!,
    '... and escaping non-alphanumerics';

like_string $result, qr!<a class="url" href="http://www.google.com/">!,
    'U<> tag should become urls';

like_string $result, qr!<a href="#startofdocument">!,
    'L<> tag should become cross references';

like_string $result, qr!<a href="#startofdocument">!,
    'A<> tag should become cross references';

like_string $result, qr!<a href="#slightlycomplex\?heading">!,
    '... with appropriate quoting';

like_string $result, qr!<a href="#next_heading">!,
    '... and non-quoting when appropriate';

done_testing;
