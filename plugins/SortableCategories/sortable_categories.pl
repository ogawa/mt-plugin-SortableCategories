# SortableCategories
# $Id$
#
# This software is provided as-is. You may use it for commercial or
# personal use. If you distribute it, please keep this notice intact.
#
# Copyright (c) 2006-2009 Hirotaka Ogawa

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
    my $pkg       = 'SortableCategories::';
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
