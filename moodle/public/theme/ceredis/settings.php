<?php
// Settings for CEREDIS theme.

defined('MOODLE_INTERNAL') || die();

if ($hassiteconfig) {
    $settings = new admin_settingpage('theme_ceredis', get_string('pluginname', 'theme_ceredis'));

    // Logo file.
    $name = 'theme_ceredis/logo';
    $title = get_string('logo', 'theme_ceredis');
    $desc = get_string('logodesc', 'theme_ceredis');
    $settings->add(new admin_setting_configstoredfile($name, $title, $desc, 'logo', 0,
        ['maxfiles' => 1, 'accepted_types' => ['.png', '.jpg', '.jpeg', '.svg']]));

    // Hero background.
    $name = 'theme_ceredis/herobg';
    $title = get_string('herobg', 'theme_ceredis');
    $desc = get_string('herobgdesc', 'theme_ceredis');
    $settings->add(new admin_setting_configstoredfile($name, $title, $desc, 'herobg', 0,
        ['maxfiles' => 1, 'accepted_types' => ['.png', '.jpg', '.jpeg']]));

    // Hero text.
    $settings->add(new admin_setting_configtext(
        'theme_ceredis/herotitle',
        get_string('herotitle', 'theme_ceredis'),
        '',
        get_string('site_title', 'theme_ceredis'),
        PARAM_TEXT
    ));

    $settings->add(new admin_setting_configtext(
        'theme_ceredis/herotagline',
        get_string('herotagline', 'theme_ceredis'),
        '',
        get_string('site_tagline', 'theme_ceredis'),
        PARAM_TEXT
    ));

    // Sponsor toggle/text/link.
    $settings->add(new admin_setting_configcheckbox(
        'theme_ceredis/sponsor_enabled',
        get_string('sponsor_enabled', 'theme_ceredis'),
        '',
        0
    ));

    $settings->add(new admin_setting_configtext(
        'theme_ceredis/sponsor_text',
        get_string('sponsor_text', 'theme_ceredis'),
        '',
        '',
        PARAM_TEXT
    ));

    $settings->add(new admin_setting_configtext(
        'theme_ceredis/sponsor_link',
        get_string('sponsor_link', 'theme_ceredis'),
        '',
        '',
        PARAM_URL
    ));

    $ADMIN->add('themes', $settings);
}
