<?php
// Ceredis child theme configuration.

defined('MOODLE_INTERNAL') || die();

$THEME->name = 'ceredis';
$THEME->parents = ['boost'];
$THEME->sheets = [];
$THEME->editor_sheets = [];
$THEME->scss = function($theme) {
    return theme_ceredis_get_main_scss_content($theme);
};
$THEME->extrascsscallback = 'theme_ceredis_get_main_scss_content';
$THEME->prescsscallback = null;
$THEME->enable_dock = false;
$THEME->hidefromselector = false;
$THEME->csstreepostprocessor = null;
$THEME->rendererfactory = 'theme_overridden_renderer_factory';
$THEME->iconsystem = '\\core\\output\\icon_system_fontawesome';
$THEME->layouts = [];
$THEME->requiredblocks = '';
$THEME->renderers = [
    'core' => 'theme_ceredis\\output\\core_renderer',
];
