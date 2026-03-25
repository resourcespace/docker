#!/bin/bash
set -e

echo "============================================"
echo "  ResourceSpace on Railway — Starting up"
echo "============================================"

# -----------------------------------------------
# 1. Set Apache to listen on Railway's PORT
# -----------------------------------------------
PORT=${PORT:-8080}
echo "Configuring Apache to listen on port $PORT..."

# Overwrite ports.conf entirely (sed can be fragile)
echo "Listen $PORT" > /etc/apache2/ports.conf

# Overwrite virtual host port
cat > /etc/apache2/sites-available/resourcespace.conf << VHOST
<VirtualHost *:${PORT}>
    ServerAdmin admin@renaissancelabs.org
    DocumentRoot /var/www/resourcespace

    <Directory /var/www/resourcespace>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    TimeOut 600

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
VHOST

# -----------------------------------------------
# 2. Set up persistent storage via single volume
# -----------------------------------------------
VOLUME_ROOT="/data"
echo "Setting up persistent storage at $VOLUME_ROOT..."

mkdir -p "$VOLUME_ROOT/filestore"
mkdir -p "$VOLUME_ROOT/include"

# Copy include files to volume on first deploy (but NOT config.php)
if [ ! -d "$VOLUME_ROOT/include/db" ]; then
    echo "  First deploy — copying include files..."
    if [ -d /var/www/resourcespace/include ] && [ ! -L /var/www/resourcespace/include ]; then
        cp -rn /var/www/resourcespace/include/* "$VOLUME_ROOT/include/" 2>/dev/null || true
    fi
fi

# Always overwrite config.php with our env-var version from the Docker image.
# This ensures Railway env vars are used for DB credentials on every deploy,
# regardless of what the setup wizard may have written previously.
if [ -f /config.php.bak ]; then
    cp -f /config.php.bak "$VOLUME_ROOT/include/config.php"
    echo "  Config: using env-var-based config.php"
fi
chown www-data:www-data "$VOLUME_ROOT/include/config.php" 2>/dev/null || true

# Symlink filestore
if [ ! -L /var/www/resourcespace/filestore ]; then
    rm -rf /var/www/resourcespace/filestore
    ln -sf "$VOLUME_ROOT/filestore" /var/www/resourcespace/filestore
    echo "  Symlinked filestore → $VOLUME_ROOT/filestore"
fi

# Symlink include
if [ ! -L /var/www/resourcespace/include ]; then
    rm -rf /var/www/resourcespace/include
    ln -sf "$VOLUME_ROOT/include" /var/www/resourcespace/include
    echo "  Symlinked include → $VOLUME_ROOT/include"
fi

chown -R www-data:www-data "$VOLUME_ROOT/filestore"
chown -R www-data:www-data "$VOLUME_ROOT/include"
chmod -R 775 "$VOLUME_ROOT/filestore"

echo "  Storage setup complete."

# -----------------------------------------------
# 3. Wait for database to be ready
# -----------------------------------------------
DB_HOST=${MYSQL_HOST:-${MYSQLHOST:-localhost}}
DB_PORT=${MYSQL_PORT:-${MYSQLPORT:-3306}}
DB_USER=${MYSQL_USER:-${MYSQLUSER:-root}}
DB_PASS=${MYSQL_PASSWORD:-${MYSQLPASSWORD:-}}

echo "Waiting for MySQL at $DB_HOST:$DB_PORT..."
MAX_RETRIES=30
RETRY_COUNT=0
while ! mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "WARNING: Could not connect to MySQL after $MAX_RETRIES attempts."
        echo "Proceeding anyway — ResourceSpace setup wizard will handle DB init."
        break
    fi
    echo "  Attempt $RETRY_COUNT/$MAX_RETRIES — waiting 2s..."
    sleep 2
done

if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "MySQL is ready!"
fi

# -----------------------------------------------
# 4. Start cron daemon (for background jobs)
# -----------------------------------------------
echo "Starting cron daemon..."
cron

# -----------------------------------------------
# 5. Ensure Apache runtime directories exist
# -----------------------------------------------
mkdir -p /var/run/apache2
mkdir -p /var/lock/apache2
rm -f /var/run/apache2/apache2.pid

# -----------------------------------------------
# 6. Start Apache in foreground
# -----------------------------------------------
echo "============================================"
echo "  ResourceSpace is live!"
echo "  URL: ${RS_BASEURL:-http://localhost:$PORT}"
echo "  Port: $PORT"
echo "  Volume: $VOLUME_ROOT"
echo "    ├── filestore (assets)"
echo "    └── include   (config)"
echo "============================================"

# Source Apache envvars and start in foreground
. /etc/apache2/envvars
exec /usr/sbin/apache2 -DFOREGROUND
