<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

// Database configuration
$CFG->dbtype    = getenv('MOODLE_DB_TYPE') ?: 'mariadb';
$CFG->dblibrary = 'native';
$CFG->dbhost    = getenv('MOODLE_DB_HOST') ?: 'db';
$CFG->dbname    = getenv('MOODLE_DB_NAME') ?: 'moodle';
$CFG->dbuser    = getenv('MOODLE_DB_USER') ?: 'moodle';
$CFG->dbpass    = getenv('MOODLE_DB_PASSWORD') ?: '';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

// Site URL - CRITICAL: must match external access URL
$CFG->wwwroot   = getenv('MOODLE_WWWROOT') ?: 'https://ecole-en-ligne.ceredis.net';

// Data directory (outside webroot for security)
$CFG->dataroot  = '/var/www/moodledata';

// Admin directory (defaults to 'admin')
$CFG->admin     = 'admin';

// Directory permissions
$CFG->directorypermissions = 02775;
$CFG->filepermissions = 0664;

// Performance settings
$CFG->cachedir = '/var/www/moodledata/cache';
$CFG->localcachedir = '/var/www/moodledata/localcache';
$CFG->tempdir = '/var/www/moodledata/temp';

// Session configuration with Redis
$CFG->session_handler_class = '\core\session\redis';
$CFG->session_redis_host = getenv('MOODLE_REDIS_HOST') ?: 'redis';
$CFG->session_redis_port = (int)(getenv('MOODLE_REDIS_PORT') ?: 6379);
$CFG->session_redis_database = (int)(getenv('MOODLE_REDIS_DATABASE') ?: 0);
$CFG->session_redis_prefix = 'moodle_session_';
$CFG->session_redis_acquire_lock_timeout = 120;
$CFG->session_redis_lock_expire = 7200;

// Cache store with Redis (désactivé - plugin manquant)
// $CFG->alternative_cache_factory_class = 'tool_forcedcache_cache_factory';

// Security settings
$CFG->cookiesecure = true; // HTTPS only
$CFG->sslproxy = true; // SSL termination at Traefik level

// IMPORTANT: reverseproxy setting removed - caused "reverseproxyabused" error
// Traefik handles proxy transparently without needing Moodle's reverse proxy mode

// Performance optimizations
$CFG->enablecompletion = true;
$CFG->enableavailability = true;
$CFG->enableoutcomes = false;
$CFG->enableportfolios = false;
$CFG->enablewebservices = true;
$CFG->enablemobilewebservice = true;

// Developer settings (disable in production)
$CFG->debug = 0; // E_ALL | E_STRICT in dev, 0 in prod
$CFG->debugdisplay = false;
$CFG->debugstringids = false;
$CFG->perfdebug = false;
$CFG->debugpageinfo = false;

// Logging
$CFG->extramemorylimit = '512M';
$CFG->sessiontimeout = 7200; // 2 hours

// Site name
$CFG->fullname = getenv('MOODLE_SITE_NAME') ?: 'École en Ligne CEREDIS';

// Force HTTPS
$CFG->loginhttps = true;

// Prevent installation wizard from running again
$CFG->upgradekey = '';

// LTI configuration (if needed)
if (getenv('LTI_CLIENT_ID')) {
    $CFG->lti_client_id = getenv('LTI_CLIENT_ID');
    $CFG->lti_client_secret = getenv('LTI_CLIENT_SECRET');
    $CFG->lti_platform_url = getenv('LTI_PLATFORM_URL');
}

// LRS configuration (xAPI/Tin Can)
if (getenv('LRS_ENDPOINT')) {
    $CFG->lrs_endpoint = getenv('LRS_ENDPOINT');
    $CFG->lrs_username = getenv('LRS_USERNAME');
    $CFG->lrs_password = getenv('LRS_PASSWORD');
}

require_once(__DIR__ . '/lib/setup.php');

// End of config.php
