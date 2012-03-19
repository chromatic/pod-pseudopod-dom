package Pod::PseudoPod::DOM::WithSections;
# ABSTRACT: a better object model for Pod::PseudoPod documents

use strict;
use warnings;

use parent 'Pod::PseudoPod::DOM';

sub parse_string_document
{
    my ($self, $document, %args) = @_;
    $self->SUPER::parse_string_document($document, %args);
    $self->_section_fixup;
    return $self;
}

sub _section_fixup
{
    my ($self) = @_;
    $self->_build_section($self->{Document}, 0);
#    use Data::Dumper;
#    print Dumper($self->{Document});
}

sub _build_section
{
    my ($self, $node, $level) = @_;
    
    my @children = @{ $node->children || [] };
    my @adjusted;
    while (@children) {
        my $kid = shift @children;
        
        if ($kid->type eq 'header' and $kid->level <= $level) {
            my $section = $self->make(Section => type => 'section', level => $kid->level, children => []);
            while (@children and not ($children[0]->type eq 'header' and $children[0]->level <= $level)) {
                $section->add_children(shift @children);
            }
            $self->_build_section($section, $level+1);
            unshift @{ $section->children }, $kid;
            push @adjusted, $section;
        } 
        else {
            push @adjusted, $kid;
        }
    }
    
    $node->children(\@adjusted);
    return $self;
}

1;
