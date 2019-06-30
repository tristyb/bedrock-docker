FROM phusion/baseimage:0.11

MAINTAINER Misha Rumbesht <m.rumbesht@gmail.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

# Add nGinx repo
RUN add-apt-repository -y ppa:nginx/stable

RUN \
  apt-get install -y software-properties-common && \
  apt-get update && apt-get upgrade -y

# Basic Requirements
RUN apt-get update
RUN apt-get install -y git unzip wget python-pip gettext sendmail

# Install nGinx
RUN \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  chown -R www-data:www-data /var/lib/nginx

# Remove default settings
RUN rm /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default

# Copy in nGinx config
COPY .docker/stages/dev/nginx/bedrock.nginx.conf /tmp/nginx.conf
RUN mv /tmp/nginx.conf /etc/nginx/nginx.conf

# Define mountable directories.
VOLUME ["/etc/nginx/certs", "/var/www", "/var/templates"]

# Expose ports.
EXPOSE 80
EXPOSE 443

# Add php-7.3 ppa
RUN LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN apt-get update

# Install php
RUN apt-get install -y php7.3-cli php7.3-common php7.3 php7.3-mysql php7.3-fpm php7.3-curl php7.3-gd php7.3-bz2 php7.3-xml

# Install jq to modify composer.json
RUN apt-get install jq -y

# This needs to be ran again for mysql for some reason
RUN apt-get update

# Install mysql server so we can use wp-cli db bits
# set default passwords for mysql
# https://www.question-defense.com/2012/11/02/install-mysql-automatically-on-ubuntu
RUN echo mysql-server mysql-server/root_password select rootpass | debconf-set-selections
RUN echo mysql-server mysql-server/root_password_again select rootpass | debconf-set-selections
# install mysql-server
RUN apt-get install mysql-server -y

WORKDIR /

# Install dockerize
ENV DOCKERIZE_VERSION v0.2.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN chmod +x composer.phar
RUN mv composer.phar /usr/local/bin/composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

# Install ngxtop, useful for debugging
RUN pip install ngxtop

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
RUN sed -i "/# server_name_in_redirect off;/ a\fastcgi_cache_path /var/run/nginx levels=1:2 keys_zone=drm_custom_cache:16m max_size=1024m inactive=60m;" /etc/nginx/nginx.conf

COPY .docker/bedrock/entry-point.sh /tmp/entry-point.sh
RUN mv /tmp/entry-point.sh /entry-point.sh
RUN chmod +x entry-point.sh
COPY .docker/bedrock/init-wordpress.sh /tmp/init-wordpress.sh
RUN mv /tmp/init-wordpress.sh /init-wordpress.sh
RUN chmod +x init-wordpress.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/entry-point.sh"]
CMD ["nginx", "-g", "daemon off;"]
