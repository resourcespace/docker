#!/bin/bash

mkdir -p /tmp/apache2/run /tmp/apache2/lock /tmp/apache2/log
export APACHE_RUN_DIR=/tmp/apache2/run
export APACHE_LOCK_DIR=/tmp/apache2/lock
export APACHE_LOG_DIR=/tmp/apache2/log
export APACHE_PID_FILE=/tmp/apache2/run/apache2.pid

CONFIG_PVC="/var/www/html/filestore/config.php"
CONFIG_DST="/var/www/html/include/config.php"

if [ -f "$CONFIG_PVC" ] && [ -s "$CONFIG_PVC" ]; then
    # Subsequent starts: restore config and fix baseurl
    echo "[entrypoint] Restoring config.php from filestore..."
    cp "$CONFIG_PVC" "$CONFIG_DST"
    if [ -n "$RS_BASEURL" ]; then
        echo "[entrypoint] Fixing baseurl to $RS_BASEURL"
        sed -i "s|^\$baseurl\s*=\s*'[^']*';|\$baseurl = '$RS_BASEURL';|g" "$CONFIG_DST"
    fi
else
    # First run: symlink config.php into the PVC so wizard writes directly there
    echo "[entrypoint] First run — symlinking config.php to filestore PVC..."
    rm -f "$CONFIG_DST"
    ln -s "$CONFIG_PVC" "$CONFIG_DST"
    echo "[entrypoint] Wizard will write config.php directly to the PVC."
fi

exec apachectl -D FOREGROUND