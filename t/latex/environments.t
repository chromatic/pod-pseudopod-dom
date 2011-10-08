use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';

use File::Slurp;
use File::Spec::Functions;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t latex test_file.pod ) ) );
my $result = parse( $file, emit_environments => { foo => 'foo' } );

like_string $result, qr/\\LaTeX/,
    '\LaTeX in a =for latex section remains intact';

like_string $result, qr/\\begin{foo}{Title}/, 'title passed is available';
done_testing;
