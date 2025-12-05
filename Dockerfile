ARG ubuntu=24.04

FROM ubuntu:${ubuntu}

LABEL org.opencontainers.image.authors="Montala Ltd"

ENV DEBIAN_FRONTEND="noninteractive"

ARG php=8.3

ARG TARGETARCH

RUN --mount=type=cache,id=ubuntu-${TARGETARCH},target=/var/lib/apt/lists,sharing=locked <<EOI
set -e
apt-get update
apt-get install -y \
    nano \
    apache2 \
    subversion \
    ghostscript \
    antiword \
    poppler-utils \
    libimage-exiftool-perl \
    cron \
    postfix \
    wget \
    php${php} \
    php${php}-apcu \
    php${php}-curl \
    php${php}-dev \
    php${php}-gd \
    php${php}-intl \
    php${php}-ldap \
    php${php}-mysqlnd \
    php${php}-mbstring \
    php${php}-zip \
    libapache2-mod-php \
    libopencv-dev \
    python3-opencv \
    python3 \
    python3-pip
apt-get install -y --no-install-recommends \
    ffmpeg \
    imagemagick
apt-get clean
EOI

RUN <<EOI
set -e
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/${php}/apache2/php.ini
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/${php}/apache2/php.ini
sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 300/g" /etc/php/${php}/apache2/php.ini
sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 1G/g" /etc/php/${php}/apache2/php.ini
EOI

RUN bash <<EOI
set -e
(
    echo '<Directory /var/www/>'
    echo -e '\tOptions FollowSymLinks'
    echo '</Directory>'
) >>/etc/apache2/sites-enabled/000-default.conf
EOI

ADD cronjob /etc/cron.daily/resourcespace

WORKDIR /var/www/html

RUN <<EOI
set -e
rm -f index.html
svn co -q https://svn.resourcespace.com/svn/rs/releases/10.7 .
mkdir -p filestore
chmod 777 filestore
chmod -R 777 include/
EOI

# Copy custom entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Start both cron and Apache
CMD ["/entrypoint.sh"]
