package Pod::PseudoPod::DOM::Role::EPUB;
# ABSTRACT: an EPUB XHTML formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;

with 'Pod::PseudoPod::DOM::Role::HTML' =>
{
    -excludes => [qw( emit_anchor emit_index emit_body )],
};

sub emit_anchor
{
    my $self   = shift;
    my $anchor = $self->get_anchor;

    return qq|<span id="$anchor"></span>|;
}

sub emit_index
{
    my $self = shift;

    my $content = $self->get_anchor;
    $content   .= $self->id if $self->type eq 'index';

    return qq|<span id="$content"></span>|;
}

sub emit_body
{
     my $self = shift;
     return <<END_HTML_HEAD . $self->emit_kids( @_ ) . <<END_HTML;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="../css/style.css" type="text/css" />
</head>
<body>
END_HTML_HEAD
</body>
</html>
END_HTML
}

1;
