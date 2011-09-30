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
}

{
    package Pod::PseudoPod::DOM::ParentElement;

    use Moose;

    extends 'Pod::PseudoPod::DOM::Element';

    has 'children',
        is      => 'ro',
        isa     => 'ArrayRef[Pod::PseudoPod::DOM::Element]',
        default => sub { [] };

    sub add
    {
        my $self = shift;
        push @{ $self->children }, @_;
    }

    sub add_children { push @{ shift->children }, @_ }
}

{
    package Pod::PseudoPod::DOM::Element::Paragraph;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Text;

    use Moose;

    extends 'Pod::PseudoPod::DOM::Element';
    has 'content', is => 'rw';

    sub add
    {
        my $self = shift;
        $self->content( shift );
    }
}

{
    my $parent = 'Pod::PseudoPod::DOM::Element::Text';

    for my $text_item (qw(
        Anchor Bold Code Entity File Footnote Italics Index Link Plain
        Subscript Superscript URL ))
    {
        Class::MOP::Class->create(
            $parent . '::' . $text_item => superclasses => [ $parent ]
        );
    }
}

{
    package Pod::PseudoPod::DOM::Element::Heading;

    use Moose;

    extends 'Pod::PseudoPod::DOM::Element';

    has 'level', is => 'ro', required => 1;
    has 'text',  is => 'rw';

    sub add
    {
        my ($self, $item) = @_;
        $self->text( $item );
    }
}

{
    package Pod::PseudoPod::DOM::Element::List;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
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

    extends 'Pod::PseudoPod::DOM::Element';

    has 'file',    is => 'rw', isa => 'Pod::PseudoPod::DOM::Element::File';
    has 'anchor',  is => 'rw', isa => 'Pod::PsuedoPod::DOM::Element::Anchor';
    has 'caption', is => 'rw', isa => 'Pod::PsuedoPod::DOM::Element::Text';
}

{
    package Pod::PseudoPod::DOM::Element::Block;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Table;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';

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

    extends 'Pod::PseudoPod::DOM::ParentElement';

    sub cells { shift->children }
}

{
    package Pod::PseudoPod::DOM::Element::TableCell;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

{
    package Pod::PseudoPod::DOM::Element::Document;

    use Moose;

    extends 'Pod::PseudoPod::DOM::ParentElement';
}

1;
