# Specify the version of PHP we use for our Chevereto
ARG PHP_VERSION=7.2.11-apache
FROM alpine as downloader

ARG CHEVERETO_VERSION=develop
RUN apk add --no-cache curl && \
    curl -sS -o /tmp/chevereto.zip -L "https://github.com/pravynandas/Chevereto-Free/archive/${CHEVERETO_VERSION}.zip" && \
    mkdir -p /extracted && \
    cd /extracted && \
    unzip /tmp/chevereto.zip  && \
    mv "Chevereto-Free-${CHEVERETO_VERSION}/" Chevereto/
COPY settings.php /extracted/Chevereto/app/settings.php

FROM php:$PHP_VERSION

# Install required packages and configure plugins + mods for Chevereto
RUN apt-get update && apt-get install -y \
        nano \
        libgd-dev && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install \
        exif \
        gd \
        mysqli \
        pdo \
        pdo_mysql \
        zip && \
    a2enmod rewrite

# Download installer script
COPY --from=downloader --chown=33:33 /extracted/Chevereto /var/www/html

# Expose the image directory as a volume
VOLUME /var/www/html/images

# DB connection environment variables
ENV CHEVERETO_DB_HOST=db CHEVERETO_DB_USERNAME=chevereto CHEVERETO_DB_PASSWORD=chevereto CHEVERETO_DB_NAME=chevereto CHEVERETO_DB_PREFIX=chv_ CHEVERETO_DB_PORT=3306
ARG BUILD_DATE
ARG CHEVERETO_VERSION=develop

# Set all required labels, we set it here to make sure the file is as reusable as possible
LABEL org.label-schema.url="https://github.com/pravynandas/docker-chevereto" \
      org.label-schema.name="Chevereto" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.version="${CHEVERETO_VERSION}" \
      org.label-schema.vcs-url="https://github.com/pravynandas/docker-chevereto" \
      maintainer="Pravynandas <pravynandas github>" \
      build_signature="Chevereto free version ${CHEVERETO_VERSION}; built on ${BUILD_DATE}; Using PHP version ${PHP_VERSION}"
