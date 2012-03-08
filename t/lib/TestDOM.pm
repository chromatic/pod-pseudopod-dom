package TestDOM;

use strict;
use warnings;

use Pod::PseudoPod::DOM;
use Pod::PseudoPod::DOM::App;

sub import
{
    my ($self, $formatter, @args) = @_;

    my @caller   = caller;
    my $filename = $caller[1] . '.tex';
    my $parse    = sub
    {
        my $doc  = parse_document( $formatter, $filename, @_ );
        my $text = $doc->emit;
        return wantarray ? ($doc, $text) : $text;
    };

    my $parse_with_anchors = sub
    {
        my ($document, %args) = @_;
        my $anchors           = $args{formatter_args}{anchors} ||= {};
        my $doc               = parse_document( $formatter, $filename,
                                                $document,  %args );

        my %full_index;
        $doc->get_index_entries;
        $doc->resolve_anchors;
        my $text = $doc->emit;
        return wantarray ? ($doc, $text, \%full_index) : $text;
    };

    do
    {
        no strict 'refs';
        *{ $caller[0] . '::' . 'parse' }              = $parse;
        *{ $caller[0] . '::' . 'parse_with_anchors' } = $parse_with_anchors;

    };
}

sub parse_document
{
    my ($formatter, $filename, $document) = splice @_, 0, 3;
    my $parser   = Pod::PseudoPod::DOM->new(
        formatter_role => $formatter,
        filename       => $filename,
        @_
    );
    $parser->parse_string_document( $document, @_ );
    return $parser->get_document;
}

1;
