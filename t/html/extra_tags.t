use strict;
use warnings;

use Test::More;

use_ok('Pod::PseudoPod::DOM') or exit;

my $parser = Pod::PseudoPod::DOM->new(
    formatter_role => 'Pod::PseudoPod::DOM::Role::XHTML'
);
isa_ok $parser, 'Pod::PseudoPod::DOM';

sub parse
{
    my $document = shift;
    my $parser = Pod::PseudoPod::DOM->new(
        formatter_role => 'Pod::PseudoPod::DOM::Role::XHTML',
        @_
    );
    $parser->parse_string_document( $document );
    $parser->get_document->emit;
}

my $result = parse( <<END_POD );
=begin epigraph

A witty saying proves nothing.

-- someone sensible, probably Voltaire

=end epigraph
END_POD

like $result, qr!<div class="epigraph">.*A witty.*&mdash;someone.*</div>!s,
    'epigraph handled correctly';

done_testing;
