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

    return "<$level>" . $self->emit_kids . "</$level>\n\n";
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

use constant { BEFORE => 0, AFTER => 1 };

my %parent_items =
(
    programlisting => [ qq|<div class="programlisting">\n\n|, q|</div>| ],
    sidebar        => [ qq|<div class="sidebar">\n\n|,        q|</div>| ],
    paragraph      => [  q|<p>|,                              q|</p>|   ],
    text_list      => [ qq|<ul>\n\n|,                         q|</ul>|  ],
    bullet_list    => [ qq|<ul>\n\n|,                         q|</ul>|  ],
    bullet_item    => [ qq|<li>|,                             q|</li>|  ],
    number_list    => [ qq|<ol>\n\n|,                         q|</ol>|  ],
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

1;
