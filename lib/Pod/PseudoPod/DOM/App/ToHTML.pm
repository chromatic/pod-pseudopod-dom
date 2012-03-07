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

    my %full_index;
    $_->resolve_references( \%full_index ) for @docs;

    # turn anchor text contents into link destinations
    # create link descriptions from anchor headers
    # generate unique IDs for index anchors
    # must process index display info?

    my @toc;

    for my $doc (@docs)
    {
        my $output  = $doc->filename;
        my $HTMLOUT = open_fh( $output, '>' );
        print {$HTMLOUT} $doc->emit;
        push @toc, $doc->emit_toc;
    }

    write_toc( @toc );
    # do not merge anchor links; throw error on duplicates!
    write_index( $corpus->get_index );
}

sub write_toc
{
    my $fh = open_fh( 'index.html', '>' );
    print {$fh} "<ul>\n", @_, "</ul>\n";
}

sub write_index
{
    my $index = shift;
    my $fh    = open_fh( 'bookindex.html', '>' );
    print {$fh} $index;
}

1;
