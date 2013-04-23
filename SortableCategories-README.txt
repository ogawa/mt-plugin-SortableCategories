NAME
    SortableCategories - Plugin for realzing Sortable Categories and Folders

DESCRIPTION
    SortableCategories plugin allows you to arrange the orders of category
    and folder lists as you need.

    This plugin is designed to work with Movable Type 4.2 or later and does
    not support dynamic publishing at this moment.

INSTALLATION
    *   Download and extract SortableCategories-<version>.zip file.

    *   Upload or copy the contents of "plugins" directory into your
        "plugins" directory.

    *   Upload or copy the contents of "mt-static/plugins" directory into
        your "mt-static/plugins" directory.

    *   After proper installation, you will find "SortableCategories" plugin
        listed on the "System Plugin Settings" screen.

HOW TO USE
    If you want to arrange the order of categories:

    *   First, go to "Manage Categories" screen (select "Categories" from
        "Manage" dropdown list)

    *   Select "Manage Category Tree" located at the right side of "Manage
        Categories" screen.

    *   In "Manage Category Tree" screen, you can arrange the category tree
        as you like. Grab a category or a subtree of categories, and drop
        them to any point of the category tree.

    *   After arranging the category tree, select "Save" button to save the
        current tree.

    You can also arrange the order of folders in the same way.

TAGS
    This plugin does not provide any tags, but one sort_method, named
    "SortableCategories::sorter".

    In order to render a "sorted" category tree, you should replace original
    "Category Archives" widget with the following one:

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

LICENSE
    This library is free software; you can redistribute it and/or modify it
    under the terms of either:

    *   the GNU General Public License as published by the Free Software
        Foundation; either version 1, or (at your option) any later version,
        or

    *   the "Artistic License" which comes with Perl.

SUPPORT
    If you have questions or need assistance with this plugin, please use
    the following link:

    <https://github.com/ogawa/mt-plugin-SortableCategories>

COPYRIGHT
    Copyright (c) 2009 Hirotaka Ogawa <hirotaka.ogawa@gmail.com>.

