<?php
# $Id$

global $mt;
$ctx = &$mt->context();

# Check to see if SortableCategories is disabled...
$switch = $mt->config('PluginSwitch');
if (isset($switch) && isset($switch['SortableCategories/sortable_categories.pl'])) {
    if (!$switch['SortableCategories/sortable_categories.pl']) {
        define('SORTABLE_CATEGORIES_ENABLED', 0);
        return;
    }
}

define('SORTABLE_CATEGORIES_ENABLED', 1);

if (SORTABLE_CATEGORIES_ENABLED) {
    # sort_method has not been supported yet.
}

?>
