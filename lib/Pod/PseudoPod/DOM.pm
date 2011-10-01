package Pod::PseudoPod::DOM;
# ABSTRACT: an object model for Pod::PseudoPod documents

use strict;
use warnings;

use parent 'Pod::PseudoPod';
use Pod::PseudoPod::DOM::Elements;

sub new
{
    my ($class, %args)      = @_;
    my $role                = delete $args{formatter_role};
    my $self                = $class->SUPER::new(@_);
    $self->{class_registry} = {};
    $self->{formatter_role} = $role;
    $self->{formatter_args} = $args{formatter_args} || {};

    $self->accept_targets( 'html', 'HTML' );
    $self->accept_targets_as_text(
        qw( author blockquote comment caution
            editor epigraph example figure important listing literal note
            production programlisting screen sidebar table tip warning )
    );

    $self->nix_X_codes(1);
    $self->nbsp_for_S(1);
    $self->codes_in_verbatim(1);

    return $self;
}

sub get_document
{
    my $self = shift;
    return $self->{Document};
}

sub make
{
    my ($self, $type, @args) = @_;
    my $registry             = $self->{class_registry};
    my $class                = $registry->{$type};

    unless ($class)
    {
        my $name = 'Pod::PseudoPod::DOM::Element::' . $type;
        $class   = $registry->{$type}
                 = $name->with_traits( $self->{formatter_role} );
    }

    return $class->new( %{ $self->{formatter_args} }, @args );
}

sub start_Document
{
    my $self = shift;

    $self->{active_elements} =
    [
        $self->{Document} = $self->make( Document => type => 'document' )
    ];
}

sub end_Document
{
    my $self = shift;
    $self->{active_elements} = [];
}

sub start_Verbatim
{
    my $self = shift;
    $self->push_element( 'Text', type => 'verbatim' );
}

sub end_Verbatim
{
    my $self = shift;
    $self->reset_to_item( 'Text', type => 'verbatim' );
}

sub reset_to_document
{
    my $self = shift;
    $self->{active_elements} = [ $self->{Document} ];
}

sub push_element
{
    my $self  = shift;
    my $child = $self->make( @_ );

    $self->{active_elements}[-1]->add_children( $child );
    push @{ $self->{active_elements } }, $child;
}

sub add_element
{
    my $self  = shift;
    my $child = $self->make( @_ );
    $self->{active_elements}[-1]->add( $child );
}

sub reset_to_item
{
    my ($self, $type, %attributes) = @_;
    my $elements                   = $self->{active_elements};
    my $class                      = 'Pod::PseudoPod::DOM::Element::' . $type;

    while (@$elements)
    {
        my $element = pop @$elements;
        next unless $element->isa( $class );

        # reset iterator
        my $attrs = keys %attributes;

        while (my ($attribute, $value) = each %attributes)
        {
            $attrs-- if $element->$attribute() eq $value;
        }

        return $element unless $attrs;
    }
}

BEGIN
{
    for my $heading ( 0 .. 4 )
    {
        my $start_meth = sub
        {
            my $self = shift;
            $self->reset_to_document;
            $self->push_element(
                Heading => level => $heading, type => 'header'
            );
        };

        my $end_meth = sub
        {
            my $self = shift;
            $self->reset_to_item( Heading => level => $heading );
        };

        do
        {
            no strict 'refs';
            *{ 'start_head' . $heading } = $start_meth;
            *{ 'end_head'   . $heading } = $end_meth;
        };
    }

    my %text_types =
    (
        Z => 'Anchor',
        I => 'Italics',
        C => 'Code',
        N => 'Footnote',
        U => 'URL',
        A => 'Link',
        G => 'Superscript',
    );

    while (my ($tag, $type) = each %text_types)
    {
        my $start_meth = sub
        {
            my $self = shift;
            $self->push_element( 'Text::' . $type, type => lc $type );
        };

        my $end_meth = sub
        {
            my $self = shift;
            $self->reset_to_item( 'Text::' . $type, type => lc $type );
        };

        do
        {
            no strict 'refs';
            *{ 'start_' . $tag } = $start_meth;
            *{ 'end_'   . $tag } = $end_meth;
        };
    }

    for my $list_type (qw( bullet text block number ))
    {
        my $start_list_meth = sub
        {
            my $self = shift;
            $self->push_element( 'List', type => $list_type . '_list' );
        };

        my $end_list_meth = sub
        {
            my $self = shift;
            my $list = $self->reset_to_item( 'List',
                type => $list_type . '_list'
            );
            $list->fixup_list if $list;
        };

        my $start_item_meth = sub
        {
            my ($self, $args) = @_;
            my @marker        = $args->{number}
                              ? (marker => $args->{number})
                              : ();

            $self->push_element( 'ListItem',
                type => $list_type . '_item', @marker
            );
        };

        my $end_item_meth = sub
        {
            my $self = shift;
            $self->reset_to_item( 'ListItem', type => $list_type . '_item' );
        };

        do
        {
            no strict 'refs';
            *{ 'start_over_' . $list_type } = $start_list_meth;
            *{ 'end_over_'   . $list_type } = $end_list_meth;
            *{ 'start_item_' . $list_type } = $start_item_meth;
            *{ 'end_item_'   . $list_type } = $end_item_meth;
        };
    }

}

sub handle_text
{
    my $self = shift;
    $self->add_element( 'Text::Plain' => type => 'text', content => shift );
}

sub start_Para
{
    my $self = shift;
    $self->push_element( Paragraph => type => 'paragraph' );
}

sub end_Para
{
    my $self = shift;
    $self->reset_to_item( Paragraph => type => 'paragraph' );
}

sub start_for
{
    my ($self, $flags) = @_;
    $self->push_element( Block => type => $flags->{target} || 'unknown_block' );
}

sub end_for
{
    my $self = shift;
    $self->reset_to_item( 'Block' );
}

1;
