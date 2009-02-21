# SortableCategories
# $Id$
#
# This software is provided as-is. You may use it for commercial or
# personal use. If you distribute it, please keep this notice intact.
#
# Copyright (c) 2009 Hirotaka Ogawa

package MT::Plugin::SortableCategories;
use strict;
use base qw( MT::Plugin );

use MT 4;

our $VERSION        = '0.01';
our $SCHEMA_VERSION = '0.01';

my $plugin = __PACKAGE__->new(
    {
        id          => 'sortable_categories',
        name        => 'SortableCategories',
        description => 'This plugin allows you to edit category tree easily.',
        doc_link    => 'http://code.as-is.net/public/wiki/SortableCategories',
        author_name => 'Hirotaka Ogawa',
        author_link => 'http://as-is.net/blog/',
        version     => $VERSION,
        schema_version => $SCHEMA_VERSION,
        l10n_class     => 'SortableCategories::L10N',
    }
);
MT->add_plugin($plugin);

sub instance { $plugin }

sub init_registry {
    my $plugin    = shift;
    my $pkg       = 'SortableCategories::CMS::';
    my $source_cb = 'MT::App::CMS::template_source.';
    my $param_cb  = 'MT::App::CMS::template_param.';
    require POSIX;
    $plugin->registry(
        {
            object_types => {
                category =>
                  { rank => 'integer indexed default ' . POSIX::INT_MAX, },
            },
            applications => {
                cms => {
                    methods => {
                        list_cat_tree => "${pkg}list_cat_tree",
                        save_cat_tree => "${pkg}save_cat_tree",
                    },
                },
            },
            callbacks => {
                "${source_cb}list_category" => "${pkg}list_category_source",
                "${source_cb}list_folder"   => "${pkg}list_category_source",
                "${param_cb}list_category"  => "${pkg}list_category_param",
                "${param_cb}list_folder"    => "${pkg}list_category_param",
                "${param_cb}edit_entry"     => "${pkg}edit_entry_param",
                "${param_cb}asset_upload"   => "${pkg}edit_entry_param",
            },
        }
    );
}

1;

__END__

=head1 NAME

SortableCategories - Plugin for realzing Sortable Categories and Folders

=head1 DESCRIPTION

SortableCategories plugin allows you to arrange the orders of category
and folder lists as you need.

This plugin is designed to work with Movable Type 4.2 or later and
does not support dynamic publishing at this moment.

=head1 INSTALLATION

=over 4

=item * Download and extract SortableCategories-<version>.zip file.

=item * Upload or copy the contents of "plugins" directory into your
"plugins" directory.

=item * Upload or copy the contents of "mt-static/plugins" directory
into your "mt-static/plugins" directory.

=item * After proper installation, you will find "SortableCategories"
plugin listed on the "System Plugin Settings" screen.

=back

=head1 HOW TO USE

If you want to arrange the order of categories:

=over 4

=item * First, go to "Manage Categories" screen (select "Categories"
from "Manage" dropdown list)

=item * Select "Manage Category Tree" located at the right side of
"Manage Categories" screen.

=item * In "Manage Category Tree" screen, you can arrange the category
tree as you like.  Grab a category or a subtree of categories, and
drop them to any point of the category tree.

=item * After arranging the category tree, select "Save" button to
save the current tree.

=back

You can also arrange the order of folders in the same way.

=head1 TAGS

This plugin does not provide any tags, but one sort_method, named
"SortableCategories::sorter".

In order to render a "sorted" category tree, you should replace
original "Category Archives" widget with the following one:

    <mt:IfArchiveTypeEnabled archive_type="Category">
    <div class="widget-archive widget-archive-category widget">
        <h3 class="widget-header">Category</h3>
        <div class="widget-content">
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
        </div>
    </div>
    </mt:IfArchiveTypeEnabled>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of either:

=over 4 

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any later
version, or

=item * the "Artistic License" which comes with Perl.

=back

=head1 SUPPORT

If you have questions or need assistance with this plugin, please
use the following link:

L<http://code.as-is.net/public/wiki/SortableCategories>

=head1 COPYRIGHT

Copyright (c) 2009 Hirotaka Ogawa <hirotaka.ogawa@gmail.com>.

=cut
