<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

defined('MOODLE_INTERNAL') || die();

$bodyattributes = $OUTPUT->body_attributes();

$templatecontext = [
    'sitename' => format_string($SITE->shortname, true, ['context' => context_course::instance(SITEID)]),
    'output' => $OUTPUT,
    'bodyattributes' => $bodyattributes,
    'loggedin' => isloggedin() && !isguestuser(),
];

echo $OUTPUT->header();
echo $OUTPUT->render_from_template('theme_ceredis/frontpage', $templatecontext);
echo $OUTPUT->footer();
