# $Id$
package SortableCategories::CMS;
use strict;

# Util: re-sort category_loop by category_rank
sub resort_category_loop {
    my ($data) = @_;
    my $children = {};
    require POSIX;
    my $int_max = POSIX::INT_MAX;
    for (@$data) {
        $_->{category_rank} ||= $int_max;
        my $list = $children->{ $_->{category_parent} } ||= [];
        push @$list, $_;
    }
    my $pusher;
    $pusher = sub {
        my ( $children, $id ) = @_;
        $id ||= 0;
        my $list = $children->{$id};
        return () unless $list && @$list;
        my @sorted_list =
          sort { $a->{category_rank} <=> $b->{category_rank} } @$list;
        my @flat;
        for (@sorted_list) {
            push @flat, $_;
            push @flat, $pusher->( $children, $_->{category_id} )
              if $children->{ $_->{category_id} };
        }
        @flat;
    };
    my @data = $pusher->( $children, 0 );
    \@data;
}

# Util: re-sort category_tree by category_rank
sub resort_category_tree {
    my ( $type, $data ) = @_;
    my $class    = MT->model($type);
    my $children = {};
    require POSIX;
    my $int_max = POSIX::INT_MAX;
    for (@$data) {
        my $cat = $class->load( $_->{id} ) or next;
        $_->{rank} = $cat->rank || $int_max;
        my $list = $children->{ $cat->parent } ||= [];
        push @$list, $_;
    }
    my $pusher;
    $pusher = sub {
        my ( $children, $id ) = @_;
        $id ||= 0;
        my $list = $children->{$id};
        return () unless $list && @$list;
        my @sorted_list =
          sort { $a->{rank} <=> $b->{rank} } @$list;
        my @flat;
        for (@sorted_list) {
            push @flat, $_;
            push @flat, $pusher->( $children, $_->{id} )
              if $children->{ $_->{id} };
        }
        @flat;
    };
    my @data = $pusher->( $children, 0 );
    \@data;
}

# Transformer for list_category.tmpl and list_folder.tmpl, which
# re-sorts "object_loop" and "category_loop" based on category_rank
# and adds "related_content" setvarblock
sub list_category_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q      = $app->param;
    my $type   = $q->param('_type') || 'category';
    my $plugin = $cb->plugin;

    $param->{object_loop} = $param->{category_loop} =
      resort_category_loop( $param->{category_loop} );

    my $header;
    my $includes = $tmpl->getElementsByTagName('include');
    for (@$includes) {
        if ( $_->getAttribute('name') =~ /header.tmpl$/ ) {
            $header = $_;
            last;
        }
    }
    return unless $header;

    require MT::Template;
    bless $header, 'MT::Template::Node';

    my $related_content = $tmpl->createElement(
        'include',
        {
            name      => 'link_' . $type . '_tree.tmpl',
            component => $plugin->id,
        }
    );
    $tmpl->insertBefore( $related_content, $header );
}

# Transformer for edit_entry.tmpl and dialog/asset_upload.tmpl, which
# re-sorts "category_tree" based on category_rank
sub edit_entry_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q = $app->param;
    my $type = $q->param('_type') eq 'entry' ? 'category' : 'folder';
    $param->{category_tree} =
      resort_category_tree( $type, $param->{category_tree} );
}

# Transformer for debugging
sub debug_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    use Data::Dumper;
    print STDERR $cb->name . ': ' . Dumper($param);
}

# CMS Method (derived from MT::CMS::Category::list)
sub list_cat_tree {
    my $app   = shift;
    my $q     = $app->param;
    my $type  = $q->param('_type') || 'category';
    my $class = $app->model($type);

    my $perms = $app->permissions;
    my $entry_class;
    my $entry_type;
    if ( $type eq 'category' ) {
        $entry_type = 'entry';
        return $app->return_to_dashboard( redirect => 1 )
          unless $perms && $perms->can_edit_categories;
    }
    elsif ( $type eq 'folder' ) {
        $entry_type = 'page';
        return $app->return_to_dashboard( redirect => 1 )
          unless $perms && $perms->can_manage_pages;
    }
    $entry_class = $app->model($entry_type);
    my $blog_id = scalar $q->param('blog_id');
    require MT::Blog;
    my $blog = MT::Blog->load($blog_id)
      or return $app->errtrans("Invalid request.");
    my %param;
    my %authors;
    my $data = $app->_build_category_list(
        blog_id    => $blog_id,
        # counts     => 1,
        # new_cat_id => scalar $q->param('new_cat_id'),
        type       => $type
    );
    if ( $blog->site_url =~ /\/$/ ) {
        $param{blog_site_url} = $blog->site_url;
    }
    else {
        $param{blog_site_url} = $blog->site_url . '/';
    }
    $data = resort_category_loop($data);
    $param{object_loop} = $param{category_loop} = $data;
    $param{saved} = $q->param('saved');
    $param{saved_deleted} = $q->param('saved_deleted');
    $app->load_list_actions( $type, \%param );

    #$param{nav_categories} = 1;
    $param{sub_object_label} =
        $type eq 'folder'
      ? $app->translate('Subfolder')
      : $app->translate('Subcategory');
    $param{object_label}        = $class->class_label;
    $param{object_label_plural} = $class->class_label_plural;
    $param{object_type}         = $type;
    $param{entry_label_plural}  = $entry_class->class_label_plural;
    $param{entry_label}         = $entry_class->class_label;
    $param{search_label}        = $param{entry_label_plural};
    $param{search_type}         = $entry_type;
    $param{screen_id} =
        $type eq 'folder'
      ? 'list-folder'
      : 'list-category';
    $param{listing_screen}      = 1;
    $app->add_breadcrumb( $param{object_label_plural} );

    $param{screen_class} = "list-${type}";
    $param{screen_class} .= " list-category"
      if $type eq 'folder';    # to piggyback on list-category styles
    my $tmpl_file = 'list_' . $type . '_tree.tmpl';
    my $plugin    = $app->component('sortable_categories');
    $plugin->load_tmpl( $tmpl_file, \%param );
}

# CMS Method
sub save_cat_tree {
    my $app   = shift;
    my $q     = $app->param;
    my $perms = $app->permissions;
    my $type  = $q->param('_type');
    my $class = $app->model($type)
      or return $app->errtrans("Invalid request.");

    if ( $type eq 'category' ) {
        return $app->errtrans("Permission denied.")
          unless $perms && $perms->can_edit_categories;
    }
    elsif ( $type eq 'folder' ) {
        return $app->errtrans("Permission denied.")
          unless $perms && $perms->can_manage_pages;
    }

    $app->validate_magic() or return;

    my $blog_id         = $q->param('blog_id');
    my $serialized_tree = $q->param('serialized_tree');

    require POSIX;
    my $int_max = POSIX::INT_MAX;
    my %parents;
    for ( split /&/, $serialized_tree ) {
        my ( $key, $cat_id ) = split /=/, $_;
        $key =~ s/\[id\]//;    # depends on scriptaculous version
        $parents{$key} = $cat_id;
        my $parent = 0;
        my $rank   = $int_max;
        if ( $key =~ m/(.+)\[(\d+)\]/ ) {
            $parent = $parents{$1} if exists $parents{$1};
            $rank = $2 + 1;
        }
        my $cat = $class->load($cat_id) or next;
        if ( $cat->parent != $parent || $cat->rank != $rank ) {
            $cat->parent($parent);
            $cat->rank($rank);
            $cat->save
              or return $app->errtrans( $cat->errstr );
        }
    }

    $app->redirect(
        $app->uri(
            mode => 'list_cat_tree',
            args => {
                _type   => $type,
                blog_id => $blog_id,
                saved   => 1,
            }
        )
    );
}

1;

__END__
