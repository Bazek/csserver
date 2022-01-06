FROM php:fpm-alpine
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>
ARG STEAM_API_KEY

RUN apk add gmp-dev && docker-php-ext-install pdo_mysql gmp

COPY --chown=www-data:www-data csx_stats /csx_stats
RUN sed s/__STEAM_API_KEY__/$STEAM_API_KEY/g -i /csx_stats/private/includes/_config.inc
