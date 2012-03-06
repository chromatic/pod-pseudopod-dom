#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Pod::PseudoPod::DOM;

exit main( @ARGV );

sub main
{
    use_ok( 'Pod::PseudoPod::DOM::Index' );

    test_simple_index();
    test_multiple_index();
    test_multiple_entries_in_one_index();
    test_subentries();
    test_subsubentries();
    test_subentry_with_entry();

    done_testing();
    return 0;
}

sub make_index_nodes
{
    my $doc   = qq|=head0 My Document\n\n|;
    my $count = 0;

    for my $tag (@_)
    {
        $doc .= qq|=head1 Index Element $count\n\n$tag\n\n|;
        $count++;
    }

    my $parser = Pod::PseudoPod::DOM->new(
        formatter_role => 'Pod::PseudoPod::DOM::Role::XHTML',
        filename       => 'dummy_file.html',
    );
    my $dom   = $parser->parse_string_document( $doc )->get_document;
    my $index = Pod::PseudoPod::DOM::Index->new;
    $index->add_entry( $_ ) for $dom->get_index_entries;

    return $index;
}

sub test_simple_index
{
    my $index = make_index_nodes( 'X<some entry>' );
    like $index->emit_index, qr!<h2>S</h2>!,
        'index should contain top-level key for all entries';
}

sub test_multiple_index
{
    my $index = make_index_nodes(
        'X<some entry>', 'X<some other entry', 'X<yet more entries>'
    );

    my $output = $index->emit_index;

    like $output, qr!<h2>S</h2>!,
        'index should contain top-level key for all entries';

    like $output, qr!<h2>Y</h2>!,
        '... always capitalized';

    like $output, qr!some entry!,       '... with text of entry';
    like $output, qr!some other entry!, '... for each entry';
    like $output, qr!yet more entries!, '... added to index';
}

sub test_multiple_entries_in_one_index
{
    my $index = make_index_nodes(
        'X<aardvark>', 'X<Balloonkeeper>', 'X<aardvark>'
    );

    my $output = $index->emit_index;
    like $output, qr!<h2>A</h2>!, 'index should contain top-level keys';
    like $output, qr!<h2>B</h2>!, '... with proper capitalization';

    like $output,
        qr!aardvark \[<a href=".+?#aardvark1">1</a>\] \[.+?vark2">2</a>\]!,
        '... with multiple entries merged';
}

sub test_subentries
{
    my $index = make_index_nodes(
        'X<animals; aardvark>', 'X<animals; blue-footed boobie>',
        'X<animals; cardinal>'
    );

    my $output = $index->emit_index;

    like $output, qr!<h2>A</h2>!, 'index should contain top-level keys';
    like $output, qr!<li><p>animals</p>\n<ul>!,
        '... with top levels of nested index entries creating lists';
    like $output, qr!<li>aardvark \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>blue-footed boobie \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>cardinal \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>aardvark.+<li>blue-footed boobie.+<li>cardinal!s,
        '... in alphabetical order';
    unlike $output, qr!<li>aardvark.+?</li>.+aardvark!s,
        '... but no duplicate entries unless necessary';
}

sub test_subsubentries
{
    my $index = make_index_nodes(
        'X<animals; a-letter; aardvark>',
        'X<animals; b-letter; blue-footed boobie>',
        'X<animals; c-letter; cardinal>',
        'X<animals; a-letter; anteater>',
    );

    my $output = $index->emit_index;

    like $output, qr!<h2>A</h2>!, 'index should contain top-level keys';
    like $output, qr!<li><p>animals</p>\n<ul>!,
        '... with top levels of nested index entries creating lists';
    like $output, qr!<li>aardvark \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>blue-footed boobie \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>cardinal \[.+?\]</li>!,
        '... with each subelement in a list item';
    like $output, qr!<li>aardvark.+<li>blue-footed boobie.+<li>cardinal!s,
        '... in alphabetical order';
    unlike $output, qr!<li>aardvark.+?</li>.+aardvark!s,
        '... but no duplicate entries unless necessary';

    like $output, qr!<li><p>animals</p>\n<ul>\n<li><p>a-letter</p>!,
        '... nesting sub-entries appropriately';
    like $output, qr!<p>a-letter.+<p>b-letter.+<p>c-letter!s,
        '... in alphabetical order';
    like $output, qr!<li>aardvark.+?<li>anteater!s,
        '... with entries in alphabetical order too';

    like $output, qr!#animals;a-letter;aardvark1!,
        '... and full anchors';
}

sub test_subentry_with_entry
{
}
