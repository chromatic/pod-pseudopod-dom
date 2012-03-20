package Pod::PseudoPod::DOM::App::ToHTML;
# ABSTRACT: helper functions for bin/ppdom2html

use strict;
use warnings;
use autodie;

use Pod::PseudoPod::DOM;
use Pod::PseudoPod::DOM::Corpus;

use Pod::PseudoPod::DOM::App qw( open_fh );

sub process_files_with_output
{
    my @docs;
    my %anchors;
    my $corpus = Pod::PseudoPod::DOM::Corpus->new;

    for my $file (@_)
    {
        my ($source, $output) = @$file;

        my $parser = Pod::PseudoPod::DOM->new(
            formatter_role => 'Pod::PseudoPod::DOM::Role::XHTML',
            formatter_args => { add_body_tags => 1, anchors => \%anchors },
            filename       => $output,
        );

        my $HTMLOUT = open_fh( $output, '>' );
        $parser->output_fh($HTMLOUT);

        $parser->no_errata_section(1); # don't put errors in doc output
        $parser->complain_stderr(1);   # output errors on STDERR instead

        die "Unable to open file ($source)\n" unless -e $source;
        $parser->parse_file( open_fh( $source ) );

        $corpus->add_document( $parser->get_document, $parser );
    }

    $corpus->write_documents;
    $corpus->write_index;
    $corpus->write_toc;
}

1;
