package TestDOM;

use Pod::PseudoPod::DOM;

sub import
{
    my ($self, $formatter, @args) = @_;

    my @caller   = caller;
    my $filename = $caller[1] . '.tex';
    my $sub      = sub
    {
        my $document = shift;
        my $parser   = Pod::PseudoPod::DOM->new(
            formatter_role => $formatter,
            filename       => $filename,
            @_
        );
        $parser->parse_string_document( $document, @_ );
        my $doc  = $parser->get_document;
        my $text = $doc->emit;
        return wantarray ? ($doc, $text) : $text;
    };

    do { no strict 'refs'; *{ $caller[0] . '::' . 'parse' } = $sub };
}

1;
