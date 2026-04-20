FROM ubuntu:24.04

LABEL org.opencontainers.image.authors="Montala Ltd"

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && apt-get install -y \
    nano \
    imagemagick \
    apache2 \
    subversion \
    ghostscript \
    antiword \
    poppler-utils \
    libimage-exiftool-perl \
    cron \
    postfix \
    wget \
    php \
    php-apcu \
    php-curl \
    php-dev \
    php-gd \
    php-intl \
    php-mysqlnd \
    php-mbstring \
    php-zip \
    libapache2-mod-php \
    ffmpeg \
    libopencv-dev \
    python3-opencv \
    python3 \
    python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/8.3/apache2/php.ini \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/8.3/apache2/php.ini \
    && sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 300/g" /etc/php/8.3/apache2/php.ini \
    && sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 1G/g" /etc/php/8.3/apache2/php.ini

# OpenShift: replace upstream Apache configs with port-8080 versions
COPY ports.conf         /etc/apache2/ports.conf
COPY 000-default.conf   /etc/apache2/sites-enabled/000-default.conf

ADD cronjob /etc/cron.daily/resourcespace

WORKDIR /var/www/html

RUN rm -f index.html \
    && svn co -q https://svn.resourcespace.com/svn/rs/releases/10.7 . \
    && mkdir -p filestore \
    && chmod 777 filestore \
    && chmod -R 777 include/

# OpenShift: make all runtime dirs world-writable so an arbitrary UID can write
RUN mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chmod -R 777 /var/run/apache2 /var/lock/apache2 /var/log/apache2 \
    && chmod -R 777 /var/www/html

# OpenShift-patched entrypoint (no cron, port 8080, tmp runtime dirs)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080

CMD ["/entrypoint.sh"]