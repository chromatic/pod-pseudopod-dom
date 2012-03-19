package Pod::PseudoPod::DOM::Elements;
# ABSTRACT: the base classes for PseudoPod DOM objects

use strict;
use warnings;

use Moose;

{
    package Pod::PseudoPod::DOM::Element;

    use Moose;
    with 'MooseX::Traits';

    has 'type', is => 'ro', required => 1;
    sub is_empty { 1 }
}

{
    package Pod::PseudoPod::DOM::ParentElement;

    use Moose;

    extends 'Pod::PseudoPod::DOM::Element';

    has 'children',
        is      => 'rw',
        isa     => 'ArrayRef[Pod::PseudoPod::DOM::Element]',
        default => sub { [] };

    sub add
    {
        my $self = shift;
        push @{ $self->children }, grep { defined } @_;
    }

    sub add_children { push @{ shift->children }, @_ }

    sub is_empty { return @{ shift->children } == 0 }
}

{
    package Pod::PseudoPod::DOM::Element::Section;

    use Moose;
    has 'level',
        is      => 'ro',
        isa     => 'Num';

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Paragraph;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Text::Plain;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
    has 'content', is => 'rw';

    sub add
    {
        my $self = shift;
        $self->content( shift );
    }

    sub is_empty { length( shift->content ) == 0 }
}

{
    package Pod::PseudoPod::DOM::Element::Linkable;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';

    has 'link',    is => 'rw', default  => '';
    has 'heading', is => 'rw', required => 1;
}

{
    package Pod::PseudoPod::DOM::Element::Text::Anchor;

    use Moose;

    extends 'Pod::PseudoPod::DOM::Element::Linkable';

    # XXX: this shouldn't be here
    sub get_filename  { shift->link               }
    sub get_anchor    { shift->emit_kids( encode => 'index_anchor' ) }
    sub get_link_text { shift->heading->emit_kids }
}

{
    package Pod::PseudoPod::DOM::Element::Text::Index;

    use Moose;
    has 'id', is => 'rw', default => 1;

    extends 'Pod::PseudoPod::DOM::Element::Linkable';

    sub get_key
    {
        my $self = shift;
        split /\s*;\s*/, join ' ', $self->emit_kids( encode => 'index_key' );
    }
}

{
    package Pod::PseudoPod::DOM::Element::Text::Link;

    use Moose;

    extends 'Pod::PseudoPod::DOM::Element::Linkable';
}

{
    my $parent = 'Pod::PseudoPod::DOM::Element::Text';

    for my $text_item (qw(
        Bold Character Code Entity File Footnote Italics
        Subscript Superscript URL ))
    {
        Class::MOP::Class->create(
            "${parent}::${text_item}" =>
            superclasses              => ['Pod::PseudoPod::DOM::ParentElement']
        );
    }
}

{
    package Pod::PseudoPod::DOM::Element::Heading;

    use Moose;
    use Scalar::Util ();

    extends 'Pod::PseudoPod::DOM::ParentElement';

    has 'level',  is => 'ro', required => 1;
    has 'anchor', is => 'rw';

    sub exclude_from_toc
    {
        my ($self, $max_depth) = @_;

        return scalar $self->emit_kids =~ /^\*/ unless defined $max_depth;
        return $self->level > $max_depth;
    }
}

{
    package Pod::PseudoPod::DOM::Element::List;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';

    sub fixup_list
    {
        my $self = shift;
        my $kids = $self->children;
        my @newkids;
        my $prev;

        for my $i (0 .. $#$kids)
        {
            my $kid = $kids->[$i];
            if ($kid->isa( 'Pod::PseudoPod::DOM::Element::ListItem' ))
            {
                push @newkids, $prev if $prev;
                $prev = $kid;
                next;
            }
            next if $kid->is_empty;

            $prev->add( $kid );
        }
        push @newkids, $prev if $prev;

        $self->children( \@newkids );
    }
}

{
    package Pod::PseudoPod::DOM::Element::ListItem;

    use Moose;
    has 'marker', is => 'ro';

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Sidebar;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';

    has 'title', is => 'rw', default => '';
}

{
    package Pod::PseudoPod::DOM::Element::Figure;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';

    has 'caption', is => 'rw', default => '';
    sub fixup_figure
    {
        my $self     = shift;
        my $children = $self->children;
        @$children = map
        {
            $_->type eq 'paragraph'
            ? @{ $_->children }
            : $_
        } @$children;
    }

    sub anchor
    {
        my $self = shift;
        for my $kid (@{ $self->children })
        {
            next unless $kid->type eq 'anchor';
            return $kid;
        }
    }

    sub file
    {
        my $self = shift;
        for my $kid (@{ $self->children })
        {
            next unless $kid->type eq 'file';
            return $kid;
        }
    }
}

{
    package Pod::PseudoPod::DOM::Element::Block;

    use Moose;

    has 'title',  is => 'rw', default => '';
    has 'target', is => 'ro', default => '';

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Table;

    use Moose;
    use List::Util 'first';

    has 'title', is => 'rw', default => '';

    extends 'Pod::PseudoPod::DOM::ParentElement';

    # make sure all kids are rows
    sub fixup
    {
        my $self     = shift;
        my $children = $self->children;
        my $kidclass = 'Pod::PseudoPod::DOM::Element::TableRow';
        my $prev     = first { $_->isa( $kidclass ) } @$children;

        for my $kid (@$children)
        {
            if ($kid->isa( $kidclass ))
            {
                $prev = $kid;
            }
            else
            {
                $prev->add( $kid );
            }
        }

        @$children = grep { $_->isa( $kidclass ) } @$children;

        $_->fixup for @$children;
    }

    sub num_cols
    {
        my $self    = shift;
        return $self->headrow->num_cells;
    }

    sub headrow
    {
        my $self = shift;
        my $rows = $self->children;

        return unless @$rows;
        return $rows->[0];
    }

    sub bodyrows
    {
        my $self = shift;
        my $rows = $self->children;

        return unless @$rows and @$rows > 1;
        return @{ $rows }[1 .. $#$rows ];
    }
}

{
    package Pod::PseudoPod::DOM::Element::TableRow;

    use Moose;
    use List::Util 'first';

    extends 'Pod::PseudoPod::DOM::ParentElement';

    # if adding non-cell to row, add to previous cell

    sub cells     { shift->children }
    sub num_cells { 0 + @{ shift->children } }

    # make sure all kids are cells
    sub fixup
    {
        my $self     = shift;
        my $children = $self->children;
        my $kidclass = 'Pod::PseudoPod::DOM::Element::TableCell';
        my $prev     = first { $_->isa( $kidclass ) } @$children;

        for my $kid (@$children)
        {
            if ($kid->isa( $kidclass ))
            {
                $prev = $kid;
            }
            else
            {
                $prev->add( $kid );
            }
        }

        @$children = grep { $_->isa( $kidclass ) } @$children;
    }
}

{
    package Pod::PseudoPod::DOM::Element::TableCell;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Document;

    use Moose;

    has 'externals', is => 'ro', default  => sub { {} };
    has 'filename',  is => 'ro', default  => '';
    has 'index',     is => 'ro', default  => sub { [] };
    has 'anchor',    is => 'ro', default  => sub { [] };
    has 'link',      is => 'ro', default  => sub { [] };

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

1;
