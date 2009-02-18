# $Id$
package SortableCategories;
use strict;
use POSIX qw( INT_MAX );

# patch to list_category
sub list_category_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $q = $app->param;
    my $type = $q->param('_type') || 'category';
    if ( $q->param('blog_id') ) {
        my $old    = q(<mt:include name="include/header.tmpl">);
        my $plugin = MT::Plugin::SortableCategories->instance;
	my $new =
q(<mt:setvarblock name="content_header" append="1"><p class="create-new-link"><a class="icon-left icon-create" href="<mt:var name="script_url">?__mode=list_cat_tree&amp;_type=<mt:var name="object_type" escape="url">&amp;blog_id=<mt:var name="blog_id" escape="url">">) . $plugin->translate('Manage [_1] Tree', $app->model($type)->class_label) . q(</a></p></mt:setvarblock>);
        $$tmpl =~ s/($old)/$new$1/;
    }
}

# re-sort category_loop by category_rank
sub resort_category_loop {
    my ($data) = @_;
    my $children = {};
    for my $cat (@$data) {
        my $list = $children->{ $cat->{category_parent} } ||= [];
        push @$list, $cat;
    }
    my @data = __pusher( $children, 0 );
    \@data;
}

sub __pusher {
    my ( $children, $id ) = @_;
    my $list = $children->{$id};
    return () unless $list && @$list;
    my @sorted_list = sort {
        ( $a->{category_rank} || INT_MAX )
          <=> ( $b->{category_rank} || INT_MAX )
    } @$list;
    my @flat;
    for (@sorted_list) {
        push @flat, $_;
        push @flat, __pusher( $children, $_->{category_id} )
          if $children->{ $_->{category_id} };
    }
    @flat;
}

sub list_category_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    $param->{object_loop} = $param->{category_loop} =
      resort_category_loop( $param->{category_loop} );
}

# derived from MT::CMS::Category::list
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
    my $data = $app->_build_category_list(
        blog_id    => $blog_id,
        new_cat_id => scalar $q->param('new_cat_id'),
        type       => $type
    );
    $data = resort_category_loop($data);
    my %param;
    if ( $blog->site_url =~ /\/$/ ) {
        $param{blog_site_url} = $blog->site_url;
    }
    else {
        $param{blog_site_url} = $blog->site_url . '/';
    }
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
    my $plugin    = MT::Plugin::SortableCategories->instance;
    my $tmpl      = $plugin->load_tmpl($tmpl_file);
    $app->build_page( $tmpl, \%param );
}

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

    my $blog_id = $q->param('blog_id');
    my $serialized_tree = $q->param('serialized_tree');

    my %cat_ids;
    my $rank = 1;
    for ( split /&/, $serialized_tree ) {
        my ( $key, $cat_id ) = split /=/, $_;
        $key =~ s/\[id\]//;    # depends on scriptaculous version
        $cat_ids{$key} = $cat_id;
        my $parent = 0;
        if ( $key =~ m/(.+\[\d+\])\[\d+\]/ ) {
            $parent = $cat_ids{$1};
        }
        my $cat = $class->load($cat_id) or next;
        if ( $cat->parent != $parent || $cat->rank != $rank ) {
            $cat->parent($parent);
            $cat->rank($rank);
            $cat->save
              or return $app->errtrans( $cat->errstr );
        }
        $rank++;
    }

    $app->redirect(
        $app->uri(
            'mode' => 'list_cat_tree',
            args   => {
                _type      => $type,
                blog_id    => $blog_id,
                saved      => 1,
            }
        )
    );
}

1;
