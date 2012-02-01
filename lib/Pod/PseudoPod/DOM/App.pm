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

    open my $fh, $mode . ':utf8', $file;
    return $fh;
}

sub resolve_anchors
{
    my ($self, $anchors, $dom_anchors) = @_;

    for my $anchor (@$dom_anchors)
    {
        $anchors->{$anchor->emit_kids} = $anchor;
    }
}

1;
