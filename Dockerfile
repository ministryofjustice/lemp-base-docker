FROM phusion/baseimage:master-amd64

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Set system locale
ENV LC_ALL="en_GB.UTF-8" \
    LANG="en_GB.UTF-8" \
    LANGUAGE="en_GB.UTF-8"

###
# INSTALL PACKAGES
###

# Upgrade & install packages
RUN add-apt-repository -y ppa:ondrej/php && \
    add-apt-repository -y ppa:ondrej/nginx && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install software-properties-common dirmngr apt-transport-https && \
    apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc' && \
    add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirrors.coreix.net/mariadb/repo/10.5/ubuntu focal main' && \
    apt-get update && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        php8.0-cli php8.0-curl php8.0-fpm php8.0-gd php8.0-mbstring php8.0-mysql php8.0-readline php8.0-xdebug php8.0-xml php8.0-zip \
        nginx nginx-extras\
        nullmailer \
        git nano \
        mariadb-client-10.5 \
        nodejs build-essential \
        unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /init

# Install composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

###
# CONFIGURE PACKAGES
###

# Add all config files
ADD conf/ /tmp/conf

# Configure nginx
RUN mv /tmp/conf/nginx/server.conf /etc/nginx/sites-available/ && \
    mv /tmp/conf/nginx/php-fpm.conf /etc/nginx/ && \
    mkdir /etc/nginx/whitelists/ && \
    echo "daemon off;" >> /etc/nginx/nginx.conf && \
    echo "# No frontend IP whitelist configured. Come one, come all!" > /etc/nginx/whitelists/site-wide.conf && \
    echo "# This file is configured at runtime." > /etc/nginx/real_ip.conf && \
    rm /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/server.conf /etc/nginx/sites-enabled/server.conf && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Configure php-fpm
RUN mv /tmp/conf/php-fpm/php-fpm.conf /etc/php/8.0/fpm && \
    mv /tmp/conf/php-fpm/php.ini /etc/php/8.0/fpm && \
    mv /tmp/conf/php-fpm/pool.conf /etc/php/8.0/fpm/pool.d && \
    rm /etc/php/8.0/fpm/pool.d/www.conf && \
    cat /tmp/conf/php-fpm/xdebug.ini >> /etc/php/8.0/mods-available/xdebug.ini && \
    phpdismod xdebug

# Configure bash
RUN echo "export TERM=xterm" >> /etc/bash.bashrc && \
    echo "alias wp=\"wp --allow-root\"" > /root/.bash_aliases && \
    sed -i -e 's/@\\h:/@\$\{SERVER_NAME\}:/' /root/.bashrc

# Cleanup /tmp/conf
RUN rm -Rf /tmp/conf

###
# CONFIGURE INIT SCRIPTS
###

ADD init/* /etc/my_init.d/
RUN chmod +x /etc/my_init.d/*

###
# CONFIGURE SERVICES
###

ADD service/* /etc/service/
RUN mkdir /etc/service/nginx && \
    mkdir /etc/service/nullmailer && \
    mkdir /etc/service/php-fpm && \
    mv /etc/service/nginx.sh /etc/service/nginx/run && \
    mv /etc/service/nullmailer.sh /etc/service/nullmailer/run && \
    mv /etc/service/php-fpm.sh /etc/service/php-fpm/run && \
    chmod +x /etc/service/nginx/run && \
    chmod +x /etc/service/nullmailer/run && \
    chmod +x /etc/service/php-fpm/run

###
# BUILD TIME COMMANDS
###

# Create app root directory
RUN mkdir /moj-app

EXPOSE 80
