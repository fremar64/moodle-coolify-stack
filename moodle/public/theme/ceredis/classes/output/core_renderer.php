<?php
// Custom renderer for CEREDIS theme.

namespace theme_ceredis\output;

defined('MOODLE_INTERNAL') || die();

global $CFG;
require_once($CFG->dirroot . '/theme/boost/classes/output/core_renderer.php');

use context_system;
use moodle_url;
use theme_boost\output\core_renderer as boost_core_renderer;

class core_renderer extends boost_core_renderer {
    /**
     * Render custom front page.
     */
    public function frontpage() {
        global $CFG, $USER;

        $context = context_system::instance();
        $isguest = isguestuser();
        $loggedin = isloggedin() && !$isguest;

        $isstudent = $loggedin && has_capability('moodle/course:view', $context) && !is_siteadmin();
        $isteacher = $loggedin && has_capability('moodle/course:update', $context);

        $data = [
            'config' => $CFG,
            'isguest' => $isguest,
            'loggedin' => $loggedin,
            'isstudent' => $isstudent,
            'isteacher' => $isteacher,
            'user' => $USER,
            'sponsor_enabled' => (bool) get_config('theme_ceredis', 'sponsor_enabled'),
            'sponsor_text' => get_config('theme_ceredis', 'sponsor_text'),
            'sponsor_link' => get_config('theme_ceredis', 'sponsor_link'),
        ];

        // Hero assets.
        $data['hero_logo'] = $this->image_url('ceredis', 'theme_ceredis');
        $data['hero_image'] = $this->image_url('hero-students', 'theme_ceredis');

        // Allow stored files overrides.
        $data['hero_logo_custom'] = $this->get_stored_file_url('logo');
        $data['hero_image_custom'] = $this->get_stored_file_url('herobg');

        return $this->render_from_template('theme_ceredis/frontpage', $data);
    }

    private function get_stored_file_url(string $key): ?string {
        global $CFG;
        $fs = get_file_storage();
        $context = context_system::instance();
        $files = $fs->get_area_files($context->id, 'theme_ceredis', $key, 0, 'itemid, filepath, filename', false);
        if (!empty($files)) {
            $file = reset($files);
            return moodle_url::make_pluginfile_url(
                $file->get_contextid(),
                $file->get_component(),
                $file->get_filearea(),
                $file->get_itemid(),
                $file->get_filepath(),
                $file->get_filename()
            )->out(false);
        }
        return null;
    }
}
