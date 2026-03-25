<?php
/**
 * ResourceSpace Configuration for Railway Deployment
 * 
 * All database and app settings are read from environment variables
 * set in the Railway dashboard. This eliminates hardcoded credentials
 * and makes the config portable across environments.
 */

// =============================================================================
// DATABASE CONNECTION
// =============================================================================

$mysql_server       = getenv('MYSQL_HOST') ?: getenv('MYSQLHOST') ?: 'localhost';
$mysql_server_port  = (int)(getenv('MYSQL_PORT') ?: getenv('MYSQLPORT') ?: 3306);
$mysql_username     = getenv('MYSQL_USER') ?: getenv('MYSQLUSER') ?: 'root';
$mysql_password     = getenv('MYSQL_PASSWORD') ?: getenv('MYSQLPASSWORD') ?: '';
$mysql_db           = getenv('MYSQL_DATABASE') ?: getenv('MYSQLDATABASE') ?: 'resourcespace';

// Leave empty for Docker/Railway (no local mysql binary)
$mysql_bin_path     = '';

// Use UTF-8 for all database connections
$mysql_charset      = 'utf8mb4';

// =============================================================================
// APPLICATION URL & PATHS
// =============================================================================

$baseurl = getenv('RS_BASEURL') ?: 'http://localhost:8080';
$baseurl = rtrim($baseurl, '/');

// Filestore — Railway volume at /data
$storagedir = '/data/filestore';

// =============================================================================
// SECURITY
// =============================================================================

$scramble_key = getenv('RS_SECRET') ?: 'ril-resourcespace-2026';
$api_scramble_key = getenv('RS_API_KEY') ?: 'ril-api-key-2026';

// =============================================================================
// EMAIL CONFIGURATION
// =============================================================================

$email_from     = getenv('RS_EMAIL_FROM') ?: 'assets@renaissancelabs.org';
$email_notify   = getenv('RS_EMAIL_NOTIFY') ?: 'assets@renaissancelabs.org';

// =============================================================================
// GENERAL SETTINGS
// =============================================================================

$defaultlanguage = 'en';
$allow_password_email = true;
$allow_share = true;
$enable_remote_apis = true;
$allow_account_request = true;
$preview_tiles = true;
$collection_download = true;
$terms_download = false;
$allowed_extensions = '';

$ffmpeg_supported_extensions = array(
    'mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', 'webm', 'mpg', 'mpeg', 'm4v'
);

// =============================================================================
// PERFORMANCE
// =============================================================================

$offline_job_queue = true;
$stats_autodelete = 365;

// =============================================================================
// RAILWAY-SPECIFIC SETTINGS
// =============================================================================

$proxy_url_detect = true;

if (strpos($baseurl, 'https://') === 0) {
    $force_https = true;
}

$debug_log = false;
