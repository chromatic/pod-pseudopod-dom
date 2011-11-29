package Pod::PseudoPod::DOM::Role::XHTML;
# ABSTRACT: an XHTML formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;
use HTML::Entities;

requires 'type';
has 'add_body_tags', is => 'ro', default => 0;
has 'emit_environments', is => 'ro', default => sub { {} };

sub accept_targets { qw( html HTML xhtml XHTML ) }

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

sub emit_plaintext
{
    my ($self, %args) = @_;
    my $content       = $self->content || '';

    if ($args{encode_html})
    {
        $content = encode_entities($content);
    }
    else
    {
        $content =~ s/\s*---\s*/&#8213;/g;
        $content =~ s/\s*--\s*/&mdash;/g;
    }

    return $content;
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
    return qq|<a name="| . $self->emit_kids . qq|"></a>|;
}

sub emit_italics
{
    my $self = shift;
    return '<em>' . $self->emit_kids . '</em>';
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
    return "<code>" . $self->emit_kids( encode_html => 1 ) . "</code>";
}

sub emit_footnote
{
    my $self = shift;
    return ' <span class="footnote">' . $self->emit_kids . '</span>';
}

sub emit_url
{
    my $self = shift;
    my $url  = $self->emit_kids;
    return qq|<a class="url" href="$url">$url</a>|;
}

sub emit_link
{
    my $self = shift;
    return qq|<a href="#| . $self->emit_kids . q|">link</a>|;
}

sub emit_superscript
{
    my $self = shift;
    return "<sup>" . $self->emit_kids . "</sup>";
}

sub emit_subscript
{
    my $self = shift;
    return "<sub>" . $self->emit_kids . "</sub>";
}

sub emit_bold
{
    my $self = shift;
    return "<strong>" . $self->emit_kids . "</strong>";
}

sub emit_file
{
    my $self = shift;
    return "<em>" . $self->emit_kids . "</em>";
}

use constant { BEFORE => 0, AFTER => 1 };

my %block_items =
(
    programlisting => [ qq|<div class="programlisting">\n\n|, q|</div>| ],
    sidebar        => [ qq|<div class="sidebar">\n\n|,        q|</div>| ],
    epigraph       => [ qq|<div class="epigraph">\n\n|,       q|</div>| ],
    blockquote     => [ qq|<div class="blockquote">\n\n|,     q|</div>| ],
);

while (my ($tag, $values) = each %block_items)
{
    my $sub = sub
    {
        my $self  = shift;
        my $title = $self->title;
        my $env   = $self->emit_environments;

        return $self->make_basic_block( $env->{$tag}, $title, @_ )
            if exists $env->{$tag};

        # deal with title somehow
        return $values->[BEFORE] . $self->emit_kids . $values->[AFTER] . "\n\n";
    };

    do { no strict 'refs'; *{ 'emit_' . $tag } = $sub };
}

my %parent_items =
(
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

sub emit_block
{
    my $self   = shift;
    my $title  = $self->title ? $self->title->emit_kids : '';
    my $target = $self->target;

    if (my $environment = $self->emit_environments->{$target})
    {
        $target = $environment;
    }
    elsif (my $meth = $self->can( 'emit_' . $target))
    {
        return $self->$meth( @_ );
    }

    return $self->make_basic_block( $self->target, $title, @_ );
}

sub make_basic_block
{
    my ($self, $target, $title, @rest) = @_;

    $title = defined $title ? qq|<h2>$title</h2>\n| : '';

    return qq|<div class="$target">\n$title|
         . $self->emit_kids( @rest )
         . qq|</div>|;
}

sub emit_index
{
    my $self = shift;
    # index count must increment for multiple instances in the same file
    # keep track of this location in gestalt index

    my $content = $self->emit_kids;;
    return qq|<a name="#$content"></a>|;
}

sub emit_table
{
    my $self    = shift;
    my $title   = $self->title->emit_kids;

    my $content = '<table>';
    $content   .= qq|<caption>$title</caption>| if $title;
    $content   .= $self->emit_kids;

    return $content;
}

sub emit_headrow
{
    my $self = shift;

    # kids should be cells
    my $content = '<tr>';

    for my $kid (@{ $self->children })
    {
        $content .= '<th>' . $kid->emit_kids . '</th>';
    }

    return $content . "</tr>\n";
}

sub emit_row
{
    my $self = shift;

    return '<tr>' . $self->emit_kids . qq|</tr>\n|;
}

sub emit_cell
{
    my $self = shift;
    return '<td>' . $self->emit_kids . qq|</td>\n|;
}

sub emit_figure
{
    my $self    = shift;
    my $caption = $self->caption;
    my $anchor  = $self->anchor;
    $anchor     = defined $anchor ? $anchor->emit : '';
    my $file    = $self->file->emit_kids;
    my $content = '<p>';

    $content   .= qq|<a name="$anchor"></a>|    if $anchor;
    $content   .= qq|<img src="$file" />|;
    $content   .= qq|<br />\n<em>$caption</em>| if $caption;
    $content   .= '</p>';

    return $content;
}

1;
