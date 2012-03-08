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
    my %files = @_;

    my @docs;
    my %anchors;
    my $corpus = Pod::PseudoPod::DOM::Corpus->new;

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

        $corpus->add_document( $parser->get_document );
    }

    # turn anchor text contents into link destinations
    # create link descriptions from anchor headers
    # generate unique IDs for index anchors
    # must process index display info?

    my @toc;
    write_toc( @toc );
    # do not merge anchor links; throw error on duplicates!

    $corpus->write_documents;
    $corpus->write_index;
}

# move into Corpus
sub write_toc
{
    my $fh = open_fh( 'index.html', '>' );
    print {$fh} "<ul>\n", @_, "</ul>\n";
}

1;
