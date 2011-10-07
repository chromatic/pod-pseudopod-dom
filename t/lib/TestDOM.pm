package TestDOM;

use Pod::PseudoPod::DOM;

sub import
{
    my ($self, $formatter, @args) = @_;

    my $caller = caller;
    my $sub    = sub
    {
        my $document = shift;
        my $parser = Pod::PseudoPod::DOM->new(
            formatter_role => $formatter,
            @_
        );
        $parser->parse_string_document( $document );
        $parser->get_document->emit;
    };

    do { no strict 'refs'; *{ $caller . '::' . 'parse' } = $sub };
}

1;
