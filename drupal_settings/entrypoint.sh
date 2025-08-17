#!/bin/bash
set -e

# Always copy settings.php to ensure it's our custom one
echo "Copying pre-configured settings.php..."
cp /var/www/docker_settings/settings.php /opt/drupal/web/sites/default/settings.php
chown www-data:www-data /opt/drupal/web/sites/default/settings.php
chmod 644 /opt/drupal/web/sites/default/settings.php

# Create the configuration sync directory with proper permissions
echo "Creating config sync directory..."
mkdir -p /opt/drupal/config/sync
chown -R www-data:www-data /opt/drupal/config
chmod -R 755 /opt/drupal/config

# Continue with the original entrypoint
exec docker-php-entrypoint "$@"