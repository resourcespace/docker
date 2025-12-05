#!/bin/bash

# Add config.php from custom location if set
if [[ -n "${CUSTOM_CONFIG_PHP_LOCATION}" ]]; then
    ln -sf "${CUSTOM_CONFIG_PHP_LOCATION}" /var/www/html/include/config.php
fi

# Start cron service
service cron start

# Ensure daily cron jobs are executable
chmod +x /etc/cron.daily/*

# Start Apache
service apache2 start

# keeps the container alive
tail -f /var/log/apache2/*.log
