package Pod::PseudoPod::DOM::App;
# ABSTRACT: helper functions shared between bin/ppdom2* modules

use strict;
use warnings;
use autodie;
use Exporter 'import';
our @EXPORT_OK = qw( open_fh );

sub open_fh
{
    my ($file, $mode) = @_;

    # default to reading
    $mode ||= '<';

    open my $fh, $mode . ':encoding(UTF-8)', $file;
    return $fh;
}

1;
