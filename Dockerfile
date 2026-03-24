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

# Enable Apache modules
RUN a2enmod rewrite headers

# Fix ServerName warning globally
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Checkout ResourceSpace via SVN (latest stable release)
RUN svn co https://svn.resourcespace.com/svn/rs/releases/10.7 /var/www/resourcespace

# Set permissions
RUN chown -R www-data:www-data /var/www/resourcespace && \
    chmod -R 755 /var/www/resourcespace

# Create filestore and include directories
RUN mkdir -p /var/www/resourcespace/filestore && \
    chown -R www-data:www-data /var/www/resourcespace/filestore

# Copy custom config and entrypoint
COPY config.php /var/www/resourcespace/include/config.php
COPY config.php /config.php.bak
COPY entrypoint.sh /entrypoint.sh
COPY apache-resourcespace.conf /etc/apache2/sites-available/resourcespace.conf
COPY cronjob /etc/cron.d/resourcespace

# Set up Apache virtual host
RUN a2dissite 000-default.conf && \
    a2ensite resourcespace.conf

# Ensure Apache log pipes are accessible
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/2 /var/log/apache2/error.log

# Set permissions on entrypoint
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
