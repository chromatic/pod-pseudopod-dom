package Pod::PseudoPod::DOM::Role::XHTML;
# ABSTRACT: an XHTML formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;
use HTML::Entities;

requires 'type';
has 'add_body_tags', is => 'ro', default => 0;

sub emit
{
    my $self = shift;
    my $type = $self->type;
    my $emit = 'emit_' . $type;

    $self->$emit( @_ );
}

sub emit_document
{
    my $self = shift;
    return $self->emit_body if $self->add_body_tags;
    return $self->emit_kids;
}

sub emit_body
{
    my $self = shift;
    return <<END_HTML_HEAD . $self->emit_kids . <<END_HTML;
<html>
<head>
<link rel="stylesheet" href="style.css" type="text/css" />
</head>
<body>

END_HTML_HEAD
</body>
</html>
END_HTML
}

sub emit_kids
{
    my $self = shift;
    join '', map { $_->emit( @_ ) } @{ $self->children }
}

sub emit_header
{
    my $self  = shift;
    my $level = 'h' . ($self->level + 1);

    return "<$level>" . $self->text->emit . "</$level>\n\n";
}

sub emit_text
{
    my ($self, %args) = @_;
    my $content       = $self->content || '';

    return encode_entities($content) if $args{encode_html};
    return $content;
}

sub emit_literal
{
    my $self      = shift;
    my @grandkids = map { $_->emit_kids } @{ $self->children };
    return "<pre>" . join( "\n", @grandkids ) . "</pre>\n\n";
}

sub emit_paragraph
{
    my $self    = shift;
    my $content = $self->emit_kids;
    return '' unless defined $content;
    return "<p>" . $content . "</p>\n\n";
}

sub emit_anchor
{
    my $self = shift;
    return qq|<a name="| . $self->content->emit . qq|"></a>|;
}

sub emit_italics
{
    my $self = shift;
    return '<em>' . $self->content->emit . '</em>';
}

sub emit_bullet_list
{
    my $self = shift;
    return "<ul>\n\n" . $self->emit_kids . "</ul>\n\n";
}

sub emit_bullet_item
{
    my $self = shift;
    return "<li>" . $self->emit_kids . "</li>\n\n";
}

sub emit_number_list
{
    my $self = shift;
    return "<ol>\n\n" . $self->emit_kids . "</ol>\n\n";
}

sub emit_number_item
{
    my $self   = shift;
    my $marker = $self->marker;
    my $number = $marker ? qq| number="$marker"| : '';
    return "<li$number>" . $self->emit_kids . "</li>\n\n";
}

sub emit_text_list
{
    my $self = shift;
    return "<ul>\n\n" . $self->emit_kids . "</ul>\n\n";
}

sub emit_text_item
{
    my $self  = shift;
    my $kids  = $self->children;
    return "<li></li>\n\n" unless @$kids;

    my $first = shift @$kids;

    return "<li><p>" . $first->emit . "</p>\n\n"
         . join( '', map { $_->emit } @$kids ) . "</li>\n\n";
}

sub emit_verbatim
{
    my $self = shift;
    return "<pre><code>" . $self->emit_kids( encode_html => 1 )
         . "</code></pre>\n\n";
}

sub emit_code
{
    my $self = shift;
    return "<code>" . $self->content->emit( encode_html => 1 ) . "</code>";
}

sub emit_footnote
{
    my $self = shift;
    return ' <span class="footnote">' . $self->content->emit . '</span>';
}

sub emit_url
{
    my $self = shift;
    my $url  = $self->content->emit;
    return qq|<a class="url" href="$url">$url</a>|;
}

sub emit_link
{
    my $self = shift;
    return qq|<a href="#| . $self->content->emit . q|">link</a>|;
}

sub emit_superscript
{
    my $self = shift;
    return "<sup>" . $self->content->emit . "</sup>";
}

sub emit_subscript
{
    my $self = shift;
    return "<sub>" . $self->content->emit . "</sub>";
}

sub emit_bold
{
    my $self = shift;
    return "<strong>" . $self->content->emit . "</strong>";
}

sub emit_file
{
    my $self = shift;
    return "<em>" . $self->content->emit . "</em>";
}

sub emit_programlisting
{
    my $self = shift;
    return q|<div class="programlisting">| . $self->emit_kids . "</div>\n\n";
}

1;
