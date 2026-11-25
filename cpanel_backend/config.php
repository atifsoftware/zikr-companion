<?php
// cPanel MySQL Configuration - Update these values from your cPanel -> MySQL Databases
define('DB_HOST', 'localhost');
define('DB_NAME', 'zikr_companion');
define('DB_USER', 'your_cpanel_db_user');
define('DB_PASS', 'your_cpanel_db_password');

// Admin Panel Password (change this before uploading to production!)
// Default password: change_me_123
define('ADMIN_PASSWORD_HASH', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');
// To set your own password, you can generate a hash in PHP or set PLAIN fallback below for initial setup:
define('ADMIN_SETUP_PASSWORD', 'zikr@admin2026');

function get_pdo(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4';
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
    return $pdo;
}

function base_url(): string {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $dir = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/\\');
    // Normalize if called from /api or /admin
    $dir = preg_replace('#/(api|admin)$#', '', $dir);
    return $scheme . '://' . $host . $dir;
}
