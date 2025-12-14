<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

defined('MOODLE_INTERNAL') || die();

$THEME->name = 'ceredis';
$THEME->parents = ['boost'];
$THEME->enable_dock = false;
$THEME->yuicssmodules = [];
$THEME->rendererfactory = 'theme_overridden_renderer_factory';
$THEME->requiredblocks = '';
$THEME->addblockposition = BLOCK_ADDBLOCK_POSITION_FLATNAV;

// Feuilles de style personnalisées
$THEME->sheets = ['ceredis'];

// Régions de blocs
$THEME->layouts = [
    'frontpage' => [
        'file' => 'frontpage.php',
        'regions' => ['side-pre'],
        'defaultregion' => 'side-pre',
        'options' => ['nonavbar' => false, 'langmenu' => true],
    ],
];

// SCSS pré et post
$THEME->prescsscallback = 'theme_ceredis_get_pre_scss';
$THEME->scss = function($theme) {
    return theme_ceredis_get_main_scss_content($theme);
};

// Paramètres
$THEME->supportscssoptimisation = false;
$THEME->yuicssmodules = [];
$THEME->enable_dock = false;
