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
=head0 Some Title

Some paragraph.

=head1 Some Title with C<Code> and I<Emphasized> and B<Bold>

Another paragraph.

Still more paragraphs.

When will the paragraphs end?

=begin sidebar

=head2 A Header I<Nested> in a Sidebar

This sidebar has a list of items:

=over 4

=item * One

=item * Deux

=item * Tres

=back

Is it not nifty?

=end sidebar

END_POD

like $result, qr!<h1>Some Title</h1>!, '=head0 to <h1> title';

like $result, qr!<h2>Some Title with <code>Code</code>!,
    'C<> tag nested in =headn';
like $result, qr!<h2>Some Title.+?<em>Emphasized</em>!,
    'I<> tag nested in =headn';
like $result, qr!<h2>Some Title.+?<strong>Bold</strong>!,
    'B<> tag nested in =headn';

like $result, qr!<div class="sidebar">[^>]+<h3>A Header!,
    '=headn nested in sidebar';

like $result, qr!<ul>[^>]+<li>One.*</div>!s,
    'list nested in sidebar';
done_testing;
