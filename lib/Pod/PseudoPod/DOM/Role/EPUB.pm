package Pod::PseudoPod::DOM::Role::EPUB;
# ABSTRACT: an EPUB XHTML formatter role for PseudoPod DOM trees

use strict;
use warnings;

use Moose::Role;

with 'Pod::PseudoPod::DOM::Role::HTML' =>
{
    -excludes => [qw( emit_anchor emit_index )],
};

sub emit_anchor
{
    my $self = shift;
    return qq|<a id="|
         . $self->emit_kids( encode => 'index_anchor' )
         . qq|"></a>|;
}

sub emit_index
{
    my $self = shift;

    my $content = $self->emit_kids( encode => 'index_anchor' );
    $content   .= $self->id if $self->type eq 'index';

    return qq|<a id="$content"></a>|;
}

1;
