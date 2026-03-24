<?php
// Database connection - reads from Railway environment variables
$mysql_server = getenv('MYSQL_HOST') ?: 'localhost';
$mysql_server_port = getenv('MYSQL_PORT') ?: 3306;
$mysql_username = getenv('MYSQL_USER') ?: 'root';
$mysql_password = getenv('MYSQL_PASSWORD') ?: '';
$mysql_db = getenv('MYSQL_DATABASE') ?: 'resourcespace';

// Base URL - set via environment variable
$baseurl = getenv('RS_BASEURL') ?: 'http://localhost';

// Filestore path
$storagedir = "/var/www/resourcespace/filestore";

// MySQL binary path - leave empty for Docker
$mysql_bin_path = "";

// Email configuration (optional - configure later)
$email_from = getenv('RS_EMAIL_FROM') ?: 'assets@renaissancelabs.org';
$email_notify = getenv('RS_EMAIL_NOTIFY') ?: 'assets@renaissancelabs.org';
?>
