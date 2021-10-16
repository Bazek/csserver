FROM php:fpm-alpine
MAINTAINER Petr Bartunek <petr.bartunek@firma.seznam.cz>

RUN docker-php-ext-install mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql
