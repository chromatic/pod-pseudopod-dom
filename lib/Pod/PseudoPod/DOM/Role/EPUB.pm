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
    return qq|<div id="|
         . $self->emit_kids( encode => 'index_anchor' )
         . qq|"></div>|;
}

sub emit_index
{
    my $self = shift;

    my $content = $self->emit_kids( encode => 'index_anchor' );
    $content   .= $self->id if $self->type eq 'index';

    return qq|<div id="$content"></div>|;
}

1;
