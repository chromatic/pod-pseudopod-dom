package Pod::PseudoPod::DOM::Role::LaTeX;
# ABSTRACT: an LaTeX formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;

requires 'type';
has 'add_body_tags',     is => 'ro', default => 0;
has 'emit_environments', is => 'ro', default => sub { {} };

sub accept_targets { 'latex' }

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

sub emit_plaintext
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

sub encode_none { return $_[1] }

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

    # Escape LaTeX-specific characters
    $text =~ s/\\/\\backslash/g;          # backslashes are special
    $text =~ s/([#\$&%_{}])/\\$1/g;
    $text =~ s/(\^)/\\char94{}/g;         # carets are special
    $text =~ s/</\\textless{}/g;
    $text =~ s/>/\\textgreater{}/g;

    $text =~ s/(\\backslash)/\$$1\$/g;    # add unescaped dollars

    # use the right beginning quotes
    $text =~ s/(^|\s)"/$1``/g;

    # and the right ending quotes
    $text =~ s/"(\W|$)/''$1/g;

    # fix the ellipses
    $text =~ s/\.{3}\s*/\\ldots /g;

    # fix the ligatures
    $text =~ s/f([fil])/f\\mbox{}$1/g unless $self->{keep_ligatures};

    # fix emdashes
    $text =~ s/\s--\s/---/g;

    # fix tildes
    $text =~ s/~/\$\\sim\$/g;

    # suggest hyphenation points for module names
    $text =~ s/::/::\\-/g;

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
    return '\\emph{' . $self->emit_kids . '}';
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
    return '\\texttt{' . $self->emit_kids . '}';
}

sub emit_footnote
{
    my $self = shift;
    return '\\footnote{' . $self->emit_kids . '}';
}

sub emit_url
{
    my $self = shift;
    return q|\\url{| . $self->emit_kids . '}';
}

sub emit_link
{
    my $self = shift;
    return qq|<a href="#| . $self->emit_kids . q|">link</a>|;
}

sub emit_superscript
{
    my $self = shift;
    return '$^{' . $self->emit_kids . '}$';
}

sub emit_subscript
{
    my $self = shift;
    return '$_{' . $self->emit_kids . '}$';
}

sub emit_bold
{
    my $self = shift;
    return '\\textbf{' . $self->emit_kids . '}';
}

sub emit_file
{
    my $self = shift;
    return '\\emph{' . $self->emit_kids . '}';
}

use constant { BEFORE => 0, AFTER => 1 };
my $escapes = "commandchars=\\\\\\{\\}";

my %parent_items =
(

    programlisting => [ qq|<div class="programlisting">\n\n|, q|</div>| ],
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

my %characters = (
    acute   => sub { qq|\\'| . shift },
    grave   => sub { qq|\\`| . shift },
    uml     => sub { qq|\\"| . shift },
    cedilla => sub { '\c' },              # ccedilla
    opy     => sub { '\copyright' },      # copy
    dash    => sub { '---' },             # mdash
    lusmn   => sub { '\pm' },             # plusmn
    mp      => sub { '\&' },              # amp
);

sub emit_character
{
    my $self    = shift;

    my $content = eval { $self->emit_kids };
    return unless defined $content;

    if (my ($char, $class) = $content =~ /(\w)(\w+)/)
    {
        return $characters{$class}->($char) if exists $characters{$class};
    }

    return Pod::Escapes::e2char( $content );
}

sub emit_index
{
    my $self = shift;
    return '\\index{' . $self->emit_kids . '|textit}>';
}

sub emit_latex
{
    my $self = shift;
    return $self->emit_kids( encode => 'none' ) . "\n";
}

sub emit_block
{
    my $self   = shift;
    my $title  = $self->title;
    my $target = $self->target;

    if (my $environment = $self->emit_environments->{$target})
    {
        $target = $environment;
    }
    elsif (my $meth = $self->can( 'emit_' . $target))
    {
        return $self->$meth( @_ );
    }

    return $self->make_basic_block( $self->target, $self->title, @_ );
}

sub make_basic_block
{
    my ($self, $target, $title, @rest) = @_;

    $title = defined $title ? qq|{$title}| : '';

    return qq|\\begin{$target}$title\n\n|
         . $self->emit_kids( @rest )
         . qq|\n\\end{$target}\n|;
}

sub encode_E_contents {}

sub emit_sidebar
{
    my $self  = shift;
    my $title = $self->title;
    my $env   = $self->emit_environments;

    return $self->make_basic_block( $env->{sidebar}, $title, @_ )
        if exists $env->{sidebar};

    if ($title)
    {
        $title = <<END_TITLE;
\\begin{center}
\\large{\\bfseries{$title}}
\\end{center}
END_TITLE
    }
    else
    {
        $title = '';
    }

    return <<END_HEADER . $self->emit_kids( @_ ) . <<END_FOOTER;
\\begin{figure}[!h]
\\begin{center}
\\framebox{
\\begin{minipage}{3.5in}
\\vspace{3pt}
$title
END_HEADER
\\vspace{3pt}
\\end{minipage}
}
\\end{center}
\\end{figure}
END_FOOTER

}

1;
