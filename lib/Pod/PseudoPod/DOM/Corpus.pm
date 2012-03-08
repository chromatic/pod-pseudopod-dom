package Pod::PseudoPod::DOM::Corpus;
# ABSTRACT: a collection of documents which share metadata elements

use strict;
use warnings;

use Moose;
use Pod::PseudoPod::DOM::Index;
use Pod::PseudoPod::DOM::App 'open_fh';

has 'index',      is => 'ro', default => sub {Pod::PseudoPod::DOM::Index->new};
has 'references', is => 'ro', default => sub { {} };
has 'contents',   is => 'ro', default => sub { [] };
has 'documents',  is => 'ro', default => sub { [] };

sub add_document
{
    my ($self, $document) = @_;
    push @{ $self->documents }, $document;
    $self->add_index_from_document(      $document );
    $self->add_references_from_document( $document );
    $self->add_contents_from_document(   $document );
}

sub add_index_from_document
{
    my ($self, $document) = @_;
    $self->index->add_document( $document );
}

sub add_references_from_document
{
    my ($self, $document) = @_;
}

sub add_contents_from_document
{
    my ($self, $document) = @_;
}

sub get_index
{
    my $self = shift;
    return $self->index->emit_index;
}

sub write_documents
{
    my $self      = shift;
    my $documents = $self->documents;

    $_->resolve_anchors for @$documents;

    for my $doc (@$documents)
    {
        my $output = $doc->filename;
        my $outfh  = open_fh( $output, '>' );
        print {$outfh} $doc->emit;
    }
}

sub write_index
{
    my $self  = shift;
    my $outfh = open_fh( 'book_index.html', '>' );
    print {$outfh} $self->get_index;
}

__PACKAGE__->meta->make_immutable;
