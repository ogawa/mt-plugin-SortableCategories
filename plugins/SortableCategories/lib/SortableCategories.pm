# $Id$
package SortableCategories;
use strict;

=head2 SortableCategories::sorter

Rank-based sorting method, which can be used as a "sort_method"
argument of mt:SubCategories and mt:TopLevelCategories.

B<Example:>

    <mt:TopLevelCategories sort_method="SortableCategories::sorter">
        <mt:SubCatIsFirst>
        <ul>
        </mt:SubCatIsFirst>
        <mt:If tag="CategoryCount">
            <li><a href="<$mt:CategoryArchiveLink$>"<mt:If tag="CategoryDescription"> title="<$mt:CategoryDescription remove_html="1" encode_html="1"$>"</mt:If>><$mt:CategoryLabel$> (<$mt:CategoryCount$>)</a>
        <mt:Else>
            <li><$mt:CategoryLabel$>
        </mt:If>
        <$mt:SubCatsRecurse$>
            </li>
        <mt:SubCatIsLast>
        </ul>
        </mt:SubCatIsLast>
    </mt:TopLevelCategories>
=cut

sub sorter ($$) {
    my ( $a, $b ) = @_;
    return $a->label cmp $b->label unless $a->can('rank') && $b->can('rank');
    return $a->label cmp $b->label if $a->rank == $b->rank;
    require POSIX;
    return ( $a->rank || POSIX::INT_MAX ) <=> ( $b->rank || POSIX::INT_MAX );
}

1;

__END__
