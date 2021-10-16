FROM php:fpm-alpine
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>

RUN docker-php-ext-install pdo_mysql

COPY --chown=www-data csx_stats /csx_stats
