# Default Dockerfile
#
# @link     https://www.hyperf.io
# @document https://doc.hyperf.io
# @contact  group@hyperf.io
# @license  https://github.com/hyperf-cloud/hyperf/blob/master/LICENSE

FROM hyperf/hyperf:7.4-alpine-v3.11-swoole
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    COMPOSER_VERSION=1.8.6 \
    APP_ENV=prod

# update
RUN set -ex \
    && apk update \
    #install mongodb.so,由于是apline版本,所以需要先安装以下包
    && apk add autoconf gcc g++ make libffi-dev openssl-dev php-pear php7-dev pcre2-dev \
    && pecl channel-update pecl.php.net \
    && pecl install mongodb \
    && touch /etc/php7/conf.d/mongodb.ini \
    && echo "extension=mongodb.so" > /etc/php7/conf.d/mongodb.ini \
    # install composer
    && wget -nv -O /usr/local/bin/composer https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod u+x /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer \
    # show php version and extensions
    && php -v \
    && php -m \
    #  ---------- some config ----------
    && cd /etc/php7 \
    # - config PHP
    && { \
        echo "upload_max_filesize=128M"; \
        echo "post_max_size=128M"; \
        echo "memory_limit=1024M"; \
        echo "date.timezone=${TIMEZONE}"; \
    } | tee conf.d/99-overrides.ini \
    # - config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    # ---------- clear works ----------
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"

COPY . /data/project

WORKDIR /data/project

#初次安装注释掉，否则报错
#RUN composer install --no-dev -o

EXPOSE 9501

#运行目录未有hyperf代码的时候需要注释掉，等安装完hyperf再打开
#ENTRYPOINT ["php", "/data/project/hyperf-skeleton/bin/hyperf.php", "start"]
#使用watch热更新运行，需要composer安装watch扩展，是替代上面start的
#ENTRYPOINT ["php", "/data/project/hyperf-skeleton/bin/hyperf.php", "server:watch"]
