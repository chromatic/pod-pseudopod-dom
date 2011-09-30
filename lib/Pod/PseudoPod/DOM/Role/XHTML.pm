package Pod::PseudoPod::DOM::Role::XHTML;

use strict;
use warnings;

use Moose::Role;

requires 'type';

sub emit
{
    my $self = shift;
    my $type = $self->type;

    my $emit = 'emit_' . $type;
    $self->$emit();
}

sub emit_document { return shift->emit_kids }

sub emit_kids { join '', map { $_->emit } @{ shift->children } }

sub emit_header
{
    my $self  = shift;
    my $level = 'h' . ($self->level + 1);

    return "<$level>" . $self->text->emit . "</$level>\n\n";
}

sub emit_text
{
    my $self = shift;
    return $self->content || '';
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
    return "<pre><code>" . $self->content->emit . "</code></pre>\n\n";
}

sub emit_code
{
    my $self = shift;
    return "<code>" . $self->content->emit . "</code>";
}

sub emit_footnote
{
    my $self = shift;
    return ' <span class="footnote">' . $self->content->emit . '</span>';
}

1;