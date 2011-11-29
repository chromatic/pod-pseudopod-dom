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

    while (my ($source, $output) = each %files)
    {
        my $parser = Pod::PseudoPod::DOM->new(
            formatter_role => 'Pod::PseudoPod::DOM::Role::XHTML',
            formatter_args => { add_body_tags => 1 },
        );

        my $HTMLOUT = open_fh( $output, '>' );
        $parser->output_fh($HTMLOUT);

        $parser->no_errata_section(1); # don't put errors in doc output
        $parser->complain_stderr(1);   # output errors on STDERR instead

        die "Unable to open file\n" unless -e $source;
        $parser->parse_file($source);
        my $doc = $parser->get_document;
        print {$HTMLOUT} $doc->emit;
    }
}

1;
