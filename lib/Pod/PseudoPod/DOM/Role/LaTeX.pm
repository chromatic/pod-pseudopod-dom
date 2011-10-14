package Pod::PseudoPod::DOM::Role::LaTeX;
# ABSTRACT: an LaTeX formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;

requires 'type';
has 'tables',            is => 'rw', default => sub { {} };
has 'filename',          is => 'ro', default => '';
has 'emit_environments', is => 'ro', default => sub { {} };

sub accept_targets { 'latex' }

sub add_table
{
    my ($self, $table) = @_;
    my $filename       = $self->filename;
    my $tables         = $self->tables;
    my $count          = keys %$tables;
    (my $id            = $filename)
                       =~ s/\.(\w+)$/'_table' . $count . '.tex'/e;

    $tables->{$id} = $table;
    return $id;
}

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
    return $self->emit_kids( document => $self );
}

sub emit_kids
{
    my $self = shift;
    join '', map { $_->emit( @_ ) } @{ $self->children }
}

sub emit_header
{
    my $self     = shift;
    my $level    = $self->level;
    my $text     = $self->emit_kids;
    my $suppress = $text =~ s/^\*// ? '*' : '';

    return qq|\\chapter${suppress}{$text}\n\n| if $level == 0;

    my $subs = 'sub' x ($level - 1);
    return qq|\\${subs}section${suppress}{$text}\n\n|;
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

sub encode_index_text
{
    my ($self, $text) = @_;

    my @terms;

    for my $term (split /;/, $text)
    {
        $term =~ s/^\s+|\s+$//g;
        $term =~ s/"/""/g;
        $term =~ s/([!|@])/"$1/g;
        $term =~ s/([#\$&%_{}])/\\$1/g;
        push @terms, $term;
    }

    return join '!', @terms;
}

sub encode_label_text
{
    my ($self, $text) = @_;
    $text =~ s/[^\w:]/-/g;

    return $text;
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
    my $self = shift;
    return join " \\\\\n", map { $_->emit_kids } @{ $self->children };
}

sub emit_anchor
{
    my $self = shift;
    return '\\label{' . $self->emit_kids( encode => 'label_text' ) . qq|}\n\n|;
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
    return "\\item " . $self->emit_kids . "\n\n";
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
    return qq|\\ppodxref{| . $self->emit_kids( encode => 'label_text' ). q|}|;
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
    return '\\emph{' . $self->emit_kids( @_ ) . '}';
}

sub emit_paragraph
{
    my $self             = shift;
    my $has_visible_text = grep { $_->type ne 'index' } @{ $self->children };
    return $self->emit_kids( @_ ) . ( $has_visible_text ? "\n\n" : '' );
}

use constant { BEFORE => 0, AFTER => 1 };
my $escapes = "commandchars=\\\\\\{\\}";

my %parent_items =
(
    text_list      => [ qq|\\begin{description}\n\n|,
                        qq|\\end{description}|                          ],
    bullet_list    => [ qq|\\begin{itemize}\n\n|,
                        qq|\\end{itemize}|                              ],
    number_list    => [ qq|\\begin{enumerate}\n\n|,
                        qq|\\end{enumerate}|                            ],
     map { $_ => [ qq|\\begin{$_}\n|, qq|\\end{$_}\n\n| ] }
         qw( programlisting epigraph blockquote )
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
    return '\\index{'
         . $self->emit_kids( encode => 'index_text' )
         . '}';
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

sub emit_table
{
    my ($self, %args) = @_;
    my $title         = $self->title;
    my $num_cols      = $self->num_cols;
    my $width         = 1.0 / $num_cols;
    my $cols          = join ' | ', map { 'X' } 1 .. $num_cols;

    my $document      = $args{document};
    my $caption       = length $title
                      ? "\\caption{" . $self->encode_index_text($title) . "}\n"
                      : '';

    my $start = "$caption\\begin{longtable}{| $cols |}\n";
    my $end   = "\\end{longtable}\n";
    my $id    = $document->add_table( $start . $self->emit_kids . $end );

    return <<TABLE_REFERENCE;
\\begin{center}
\\LTXtable{\\linewidth}{$id}
\\end{center}
TABLE_REFERENCE
}

sub emit_headrow
{
    my $self = shift;
    return "\\hline\n\\rowcolor[gray]{.9}\n" . $self->emit_row;
}

sub emit_row
{
    my $self     = shift;
    my $contents = join ' & ', map { $_->emit } @{ $self->children };
    return $contents . " \\\\ \\hline\n";
}

sub emit_cell
{
    my $self = shift;
    return $self->emit_kids;
}

sub emit_figure
{
    my $self    = shift;
    my $caption = $self->caption;
    $caption    = defined $caption
                ? '\\caption{' . $self->encode_text( $caption ) . "}\n"
                : '';

    my $anchor  = $self->anchor;
    $anchor     = defined $anchor ? $anchor->emit : '';

    my $file    = $self->file->emit_kids( encode => 'none' );

    return <<END_FIGURE;
\\begin{figure}[!h]
\\centering
\\includegraphics[width=\\linewidth]{$file}
$caption$anchor\\end{figure}
END_FIGURE
}

1;
