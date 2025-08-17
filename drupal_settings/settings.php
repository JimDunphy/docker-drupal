<?php

// @see https://www.drupal.org/node/1816990
// phpcs:disable Generic.Arrays.DisallowLongArraySyntax
$databases['default']['default'] = [
  'database' => getenv('MARIADB_DATABASE') ?: 'drupal',
  'username' => getenv('MARIADB_USER') ?: 'drupal',
  'password' => getenv('MARIADB_PASSWORD') ?: 'drupal',
  'prefix' => '',
  'host' => 'mariadb',  // This is the service name in docker-compose.yml
  'port' => '3306',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
  'driver' => 'mysql',
];

// Salt for one-time login links, cancel links, form tokens, etc.
$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT') ?: 'default_salt_for_development_only_change_in_production';

// Location of the site configuration files.
$settings['config_sync_directory'] = '/opt/drupal/config/sync';

// Access control for update.php script.
$settings['update_free_access'] = FALSE;

// Default PHP settings.
ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);
ini_set('session.gc_maxlifetime', 200000);
ini_set('session.cookie_lifetime', 2000000);
ini_set('pcre.backtrack_limit', 200000);
ini_set('pcre.recursion_limit', 200000);

// If you want to override any settings, you can do so here.
// For example, to enable debug mode:
// $settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
// $config['system.performance']['css']['preprocess'] = FALSE;
// $config['system.performance']['js']['preprocess'] = FALSE;
// $settings['cache']['bins']['render'] = 'cache.backend.null';
// $settings['cache']['bins']['page'] = 'cache.backend.null';
// $settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
// $settings['extension_discovery_scan_tests'] = TRUE;
// $settings['rebuild_access'] = TRUE;
// $settings['skip_permissions_hardening'] = TRUE;

// Load services definition file.
$settings['container_yamls'][] = $app_root . '/' . $site_path . '/services.yml';
