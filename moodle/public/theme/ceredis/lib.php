<?php
// Library for CEREDIS theme.

defined('MOODLE_INTERNAL') || die();

/**
 * Returns SCSS content for the theme.
 */
function theme_ceredis_get_main_scss_content($theme) {
    global $CFG;

    $scsspath = $CFG->dirroot . '/theme/ceredis/scss/custom.scss';
    if (is_readable($scsspath)) {
        return file_get_contents($scsspath);
    }
    return '';
}
