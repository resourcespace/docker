# ResourceSpace on Railway
# Based on the official ResourceSpace Docker image
# Modified for Railway deployment (no docker-compose, env-based config)

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    cron \
    curl \
    ffmpeg \
    ghostscript \
    git \
    imagemagick \
    libapache2-mod-php \
    libimage-exiftool-perl \
    mariadb-client \
    php \
    php-apcu \
    php-cli \
    php-curl \
    php-dev \
    php-gd \
    php-imap \
    php-intl \
    php-ldap \
    php-mbstring \
    php-mysql \
    php-xml \
    php-zip \
    poppler-utils \
    subversion \
    antiword \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Configure PHP for large file uploads
RUN sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php/*/apache2/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 512M/' /etc/php/*/apache2/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 512M/' /etc/php/*/apache2/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php/*/apache2/php.ini && \
    sed -i 's/max_input_time = .*/max_input_time = 300/' /etc/php/*/apache2/php.ini

# Enable Apache modules and fix ServerName warning
RUN a2enmod rewrite headers && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Create placeholder vhost (entrypoint.sh overwrites this at runtime with correct PORT)
RUN printf '<VirtualHost *:8080>\n\
    DocumentRoot /var/www/resourcespace\n\
    <Directory /var/www/resourcespace>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
</VirtualHost>\n' > /etc/apache2/sites-available/resourcespace.conf && \
    a2dissite 000-default.conf && \
    a2ensite resourcespace.conf

# Checkout ResourceSpace via SVN (latest stable release)
RUN svn co https://svn.resourcespace.com/svn/rs/releases/10.7 /var/www/resourcespace

# Set permissions
RUN chown -R www-data:www-data /var/www/resourcespace && \
    chmod -R 755 /var/www/resourcespace

# Create filestore directory
RUN mkdir -p /var/www/resourcespace/filestore && \
    chown -R www-data:www-data /var/www/resourcespace/filestore

# Copy config and entrypoint
COPY config.php /var/www/resourcespace/include/config.php
COPY config.php /config.php.bak
COPY entrypoint.sh /entrypoint.sh
COPY cronjob /etc/cron.d/resourcespace

# Ensure Apache log pipes work in container
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/2 /var/log/apache2/error.log

# Set permissions
RUN chmod +x /entrypoint.sh && \
    chmod 0644 /etc/cron.d/resourcespace && \
    chown www-data:www-data /var/www/resourcespace/include/config.php

# Railway uses PORT env var — default to 8080
ENV PORT=8080
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
