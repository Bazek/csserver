FROM php:fpm-alpine
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>

RUN apk add gmp-dev && docker-php-ext-install pdo_mysql gmp

COPY --chown=www-data:www-data csx_stats /csx_stats
