package Pod::PseudoPod::DOM::App::ToHTML;
# ABSTRACT: helper functions for bin/ppdom2html

use strict;
use warnings;
use autodie;

use Pod::PseudoPod::DOM;
use Pod::PseudoPod::DOM::App qw( open_fh );

sub process_files_with_output
{
    my %files = @_;

    my @docs;
    my %anchors;

    while (my ($source, $output) = each %files)
    {
        my $parser = Pod::PseudoPod::DOM->new(
            formatter_role => 'Pod::PseudoPod::DOM::Role::XHTML',
            formatter_args => { add_body_tags => 1, anchors => \%anchors },
            filename       => $output,
        );

        my $HTMLOUT = open_fh( $output, '>' );
        $parser->output_fh($HTMLOUT);

        $parser->no_errata_section(1); # don't put errors in doc output
        $parser->complain_stderr(1);   # output errors on STDERR instead

        die "Unable to open file\n" unless -e $source;
        $parser->parse_file($source);

        push @docs, $parser->get_document;
    }

    $_->resolve_references for @docs;

    # turn anchor text contents into link destinations
    # create link descriptions from anchor headers
    # generate unique IDs for index anchors
    # must process index display info?

    for my $doc (@docs)
    {
        my $output  = $doc->filename;
        my $HTMLOUT = open_fh( $output, '>' );
        print {$HTMLOUT} $doc->emit;
    }

    # do not merge anchor links; throw error on duplicates!
}

1;
