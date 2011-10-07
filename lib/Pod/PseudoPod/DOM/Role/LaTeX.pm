package Pod::PseudoPod::DOM::Role::LaTeX;
# ABSTRACT: an LaTeX formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;

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
    my $level = $self->level;

    return q|\\chapter{| . $self->emit_kids . qq|}\n\n| if $level == 0;

    my $subs = 'sub' x ($level - 1);
    return qq|\\${subs}section*{| . $self->emit_kids . qq|}\n\n|;
}

sub emit_text
{
    my ($self, %args) = @_;
    my $content       = $self->content || '';

    if (my $encode = $args{encode})
    {
        my $method = 'encode_' . $encode;
        return $self->$method( $content );
    }

    return $self->encode_text( $content );
}

sub encode_verbatim_text
{
    my ($self, $text) = @_;

    $text =~ s/([{}])/\\$1/g;
    $text =~ s/\\(?![{}])/\\textbackslash{}/g;

    return $text;
}

sub encode_text
{
    my ($self, $text) = @_;

    # use the right beginning quotes
    $text =~ s/(^|\s)"/$1``/g;

    # and the right ending quotes
    $text =~ s/"(\W|$)/''$1/g;

    return $text;
}

sub emit_literal
{
    my $self      = shift;
    my @grandkids = map { $_->emit_kids } @{ $self->children };
    return qq|<div class="literal">| . join( "\n", @grandkids ) . "</div>\n\n";
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

sub emit_number_item
{
    my $self   = shift;
    my $marker = $self->marker;
    my $number = $marker ? qq| number="$marker"| : '';
    return "<li$number>" . $self->emit_kids . "</li>\n\n";
}

sub emit_text_item
{
    my $self  = shift;
    my $kids  = $self->children;
    return qq|\\item[]\n| unless @$kids;

    my $first = (shift @$kids)->emit;
    my $prelude = $first =~ /\D/
                ?  q|\\item[] | . $first
                : qq|\\item[$first]|;

    return $prelude . "\n\n" . join( '', map { $_->emit } @$kids );
}

sub emit_bullet_item
{
    my $self  = shift;
    my $kids  = $self->children;
    return qq|\\item\n| unless @$kids;

    my $first = shift @$kids;

    return q|\\item | . $first->emit . "\n\n"
         . join( '', map { $_->emit } @$kids );
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

use constant { BEFORE => 0, AFTER => 1 };
my $escapes = "commandchars=\\\\\\{\\}";

my %parent_items =
(

    programlisting => [ qq|<div class="programlisting">\n\n|, q|</div>| ],
    sidebar        => [ qq|<div class="sidebar">\n\n|,        q|</div>| ],
    epigraph       => [ qq|<div class="epigraph">\n\n|,       q|</div>| ],
    blockquote     => [ qq|<div class="blockquote">\n\n|,     q|</div>| ],
    paragraph      => [  q||,                                 q||       ],
    text_list      => [ qq|\\begin{description}\n\n|,
                        qq|\\end{description}|                          ],
    bullet_list    => [ qq|\\begin{itemize}\n\n|,
                        qq|\\end{itemize}|                              ],
    number_list    => [ qq|\\begin{itemize}\n\n|,
                        qq|\\end{itemize}|                              ],
);

while (my ($tag, $values) = each %parent_items)
{
    my $sub = sub
    {
        my $self = shift;
        return $values->[BEFORE] . $self->emit_kids . $values->[AFTER] . "\n\n";
    };

    do { no strict 'refs'; *{ 'emit_' . $tag } = $sub };
}

sub emit_verbatim
{
    my $self = shift;
    return qq|\\scriptsize\n\\begin{Verbatim}[$escapes]\n|
         . $self->emit_kids( encode => 'verbatim_text' )
         . qq|\n\\end{Verbatim}\n\\normalsize\n|;
}

sub emit_screen
{
    my $self = shift;
    return qq|\\begin{Verbatim}[$escapes,label=Program output]\n|
         . $self->emit_kids( encode => 'verbatim_text' )
         . qq|\n\\end{Verbatim}|;
}

1;
