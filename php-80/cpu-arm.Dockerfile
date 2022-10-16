FROM public.ecr.aws/lambda/provided:al2-arm64 as binary

# Work in a temporary /bref dir to avoid any conflict/mixup with other /opt files
# /bref will eventually be moved to /opt
RUN mkdir /bref \
&&  mkdir /bref/bin \
&&  mkdir /bref/lib \
&&  mkdir -p /bref/bref/extensions

RUN yum install -y amazon-linux-extras

RUN amazon-linux-extras enable php8.0

RUN yum install -y curl php-cli php-sodium unzip

# These files are included on Amazon Linux 2

# RUN cp /lib64/librt.so.1 /bref/lib/librt.so.1
# RUN cp /lib64/libstdc++.so.6 /bref/lib/libstdc++.so.6
# RUN cp /lib64/libutil.so.1 /bref/lib/libutil.so.1
# RUN cp /lib64/libxml2.so.2 /bref/lib/libxml2.so.2
# RUN cp /lib64/libssl.so.10 /bref/lib/libssl.so.10
# RUN cp /lib64/libz.so.1 /bref/lib/libz.so.1
# RUN cp /lib64/libselinux.so.1 /bref/lib/libselinux.so.1
# RUN cp /lib64/libssh2.so.1 /bref/lib/libssh2.so.1
# RUN cp /lib64/libunistring.so.0 /bref/lib/libunistring.so.0
# RUN cp /lib64/libsasl2.so.3 /bref/lib/libsasl2.so.3
# RUN cp /lib64/libssl3.so /bref/lib/libssl3.so
# RUN cp /lib64/libsmime3.so /bref/lib/libsmime3.so

# PHP Binary
RUN cp /usr/bin/php /bref/bin/php && chmod +x /bref/bin/php
RUN cp /lib64/libedit.so.0 /bref/lib/libedit.so.0
RUN cp /lib64/libncurses.so.6 /bref/lib/libncurses.so.6
#RUN cp /lib64/libcrypt.so.1 /bref/lib/libcrypt.so.1
#RUN cp /lib64/libresolv.so.2 /bref/lib/libresolv.so.2
#RUN cp /lib64/libm.so.6 /bref/lib/libm.so.6
#RUN cp /lib64/libdl.so.2 /bref/lib/libdl.so.2
#RUN cp /lib64/libgssapi_krb5.so.2 /bref/lib/libgssapi_krb5.so.2
#RUN cp /lib64/libkrb5.so.3 /bref/lib/libkrb5.so.3
#RUN cp /lib64/libk5crypto.so.3 /bref/lib/libk5crypto.so.3
#RUN cp /lib64/libcom_err.so.2 /bref/lib/libcom_err.so.2
#RUN cp /lib64/libcrypto.so.10 /bref/lib/libcrypto.so.10
#RUN cp /lib64/libc.so.6 /bref/lib/libc.so.6
#RUN cp /lib64/libpthread.so.0 /bref/lib/libpthread.so.0
#RUN cp /lib64/ld-linux-x86-64.so.2 /bref/lib/ld-linux-x86-64.so.2
#RUN cp /lib64/libgcc_s.so.1 /bref/lib/libgcc_s.so.1
#RUN cp /lib64/liblzma.so.5 /bref/lib/liblzma.so.5
#RUN cp /lib64/libkrb5support.so.0 /bref/lib/libkrb5support.so.0
#RUN cp /lib64/libkeyutils.so.1 /bref/lib/libkeyutils.so.1
#RUN cp /lib64/libtinfo.so.6 /bref/lib/libtinfo.so.6
#RUN cp /lib64/libpcre.so.1 /bref/lib/libpcre.so.1

# Default Extensions
RUN cp /usr/lib64/php/modules/ctype.so /bref/bref/extensions/ctype.so
RUN cp /usr/lib64/php/modules/exif.so /bref/bref/extensions/exif.so
RUN cp /usr/lib64/php/modules/fileinfo.so /bref/bref/extensions/fileinfo.so
RUN cp /usr/lib64/php/modules/ftp.so /bref/bref/extensions/ftp.so
RUN cp /usr/lib64/php/modules/gettext.so /bref/bref/extensions/gettext.so
RUN cp /usr/lib64/php/modules/iconv.so /bref/bref/extensions/iconv.so
RUN cp /usr/lib64/php/modules/sockets.so /bref/bref/extensions/sockets.so
RUN cp /usr/lib64/php/modules/tokenizer.so /bref/bref/extensions/tokenizer.so

# cURL
RUN cp /usr/lib64/php/modules/curl.so /bref/bref/extensions/curl.so
#RUN cp /lib64/libcurl.so.4 /bref/lib/libcurl.so.4
#RUN cp /lib64/libnghttp2.so.14 /bref/lib/libnghttp2.so.14
#RUN cp /lib64/libidn2.so.0 /bref/lib/libidn2.so.0
#RUN cp /lib64/libldap-2.4.so.2 /bref/lib/libldap-2.4.so.2
#RUN cp /lib64/liblber-2.4.so.2 /bref/lib/liblber-2.4.so.2
#RUN cp /lib64/libnss3.so /bref/lib/libnss3.so
#RUN cp /lib64/libnssutil3.so /bref/lib/libnssutil3.so
#RUN cp /lib64/libplds4.so /bref/lib/libplds4.so
#RUN cp /lib64/libplc4.so /bref/lib/libplc4.so
#RUN cp /lib64/libnspr4.so /bref/lib/libnspr4.so

# sodium
RUN cp /usr/lib64/php/modules/sodium.so /bref/bref/extensions/sodium.so
RUN cp /usr/lib64/libsodium.so.23 /bref/lib/libsodium.so.23

COPY tests/test_1_binary.php /bref/tests/
COPY tests/test_2_default_extensions.php /bref/tests/

FROM binary as extensions

RUN yum install -y \
    php-mbstring \
    php-bcmath \
    php-dom \
    php-mysqli \
    php-mysqlnd \
    php-opcache \
    php-pdo \
    php-pdo_mysql \
    php-phar \
    php-posix \
    php-simplexml \
    php-soap \
    php-xml \
    php-xmlreader \
    php-xmlwriter \
    php-xsl \
    php-intl \
    php-pdo_pgsql
    #php-apcu NOT WORKING

RUN cp /usr/lib64/php/modules/mbstring.so /bref/bref/extensions/mbstring.so
RUN cp /usr/lib64/libonig.so.2 /bref/lib/libonig.so.2

# mysqli depends on mysqlnd
RUN cp /usr/lib64/php/modules/mysqli.so /bref/bref/extensions/mysqli.so
RUN cp /usr/lib64/php/modules/mysqlnd.so /bref/bref/extensions/mysqlnd.so

#RUN cp /usr/lib64/libsqlite3.so.0 /bref/lib/libsqlite3.so.0
RUN cp /usr/lib64/php/modules/sqlite3.so /bref/bref/extensions/sqlite3.so

RUN cp /usr/lib64/libgpg-error.so.0 /bref/lib/libgpg-error.so.0
RUN cp /usr/lib64/libgcrypt.so.11 /bref/lib/libgcrypt.so.11
RUN cp /usr/lib64/libexslt.so.0 /bref/lib/libexslt.so.0
RUN cp /usr/lib64/libxslt.so.1 /bref/lib/libxslt.so.1
RUN cp /usr/lib64/php/modules/xsl.so /bref/bref/extensions/xsl.so

RUN cp /usr/lib64/libicuio.so.50 /bref/lib/libicuio.so.50
RUN cp /usr/lib64/libicui18n.so.50 /bref/lib/libicui18n.so.50
RUN cp /usr/lib64/libicuuc.so.50 /bref/lib/libicuuc.so.50
RUN cp /usr/lib64/libicudata.so.50 /bref/lib/libicudata.so.50
RUN cp /usr/lib64/php/modules/intl.so /bref/bref/extensions/intl.so

#RUN cp /usr/lib64/php/modules/apcu.so /bref/bref/extensions/apcu.so

RUN cp /usr/lib64/libpq.so.5 /bref/lib/libpq.so.5
#RUN cp /usr/lib64/libldap_r-2.4.so.2 /bref/lib/libldap_r-2.4.so.2
RUN cp /usr/lib64/php/modules/pdo_pgsql.so /bref/bref/extensions/pdo_pgsql.so

RUN cp /usr/lib64/php/modules/bcmath.so /bref/bref/extensions/bcmath.so
RUN cp /usr/lib64/php/modules/dom.so /bref/bref/extensions/dom.so
RUN cp /usr/lib64/php/modules/opcache.so /bref/bref/extensions/opcache.so
RUN cp /usr/lib64/php/modules/pdo.so /bref/bref/extensions/pdo.so
RUN cp /usr/lib64/php/modules/pdo_mysql.so /bref/bref/extensions/pdo_mysql.so
RUN cp /usr/lib64/php/modules/pdo_sqlite.so /bref/bref/extensions/pdo_sqlite.so
RUN cp /usr/lib64/php/modules/phar.so /bref/bref/extensions/phar.so
RUN cp /usr/lib64/php/modules/posix.so /bref/bref/extensions/posix.so
RUN cp /usr/lib64/php/modules/simplexml.so /bref/bref/extensions/simplexml.so
RUN cp /usr/lib64/php/modules/soap.so /bref/bref/extensions/soap.so
RUN cp /usr/lib64/php/modules/xml.so /bref/bref/extensions/xml.so
RUN cp /usr/lib64/php/modules/xmlreader.so /bref/bref/extensions/xmlreader.so
RUN cp /usr/lib64/php/modules/xmlwriter.so /bref/bref/extensions/xmlwriter.so

COPY tests/test_3_additional_extensions.php /bref/tests/
COPY tests/test_6_disabled_extensions.php /bref/tests/
COPY tests/test_6_manual_enabling_extensions.php /bref/tests/
COPY tests/test_6_manual_extensions.ini /bref/tests/

FROM public.ecr.aws/lambda/provided:al2-arm64 as isolation

COPY --from=extensions /bref /opt

FROM isolation as function

COPY common/function/bref.ini /opt/bref/etc/php/conf.d/
COPY common/function/bref-extensions.ini /opt/bref/etc/php/conf.d/

COPY common/function/bootstrap.sh /opt/bootstrap
# Copy files to /var/runtime to support deploying as a Docker image
COPY common/function/bootstrap.sh /var/runtime/bootstrap
RUN chmod +x /opt/bootstrap && chmod +x /var/runtime/bootstrap

COPY common/function/bootstrap.php /opt/bref/bootstrap.php

COPY tests/test_4_function_handler.php /opt/tests/test_4_function_handler.php
COPY tests/test_4_function_invocation.php /opt/tests/test_4_function_invocation.php
COPY tests/test_4_php.ini /var/task/php/conf.d/php.ini

FROM alpine:3.14 as zip-function

RUN apk add zip

COPY --from=function /opt /opt

RUN rm /opt/tests -rf && rm /var/task/test_5_fpm_handler.php -f

WORKDIR /opt

RUN zip --quiet --recurse-paths /tmp/layer.zip .

# Up until here the entire file has been designed as a top-down reading/execution.
# Everything necessary for the `function` layer has been installed, isolated and
# packaged. Now we'll go back one step and start from the extensions so that we
# can install fpm. Then we'll start the fpm layer and quickly isolate fpm.

FROM extensions as fpm-extension

RUN yum install -y php-fpm

FROM isolation as fpm

COPY --from=fpm-extension /usr/sbin/php-fpm /opt/bin/php-fpm

COPY --from=fpm-extension /usr/lib64/libsystemd.so.0 /opt/lib/libsystemd.so.0
COPY --from=fpm-extension /usr/lib64/liblz4.so.1 /opt/lib/liblz4.so.1
COPY --from=fpm-extension /usr/lib64/libgcrypt.so.11 /opt/lib/libgcrypt.so.11
COPY --from=fpm-extension /usr/lib64/libgpg-error.so.0 /opt/lib/libgpg-error.so.0
COPY --from=fpm-extension /usr/lib64/libdw.so.1 /opt/lib/libdw.so.1
#COPY --from=fpm-extension /usr/lib64/libacl.so.1 /opt/lib/libacl.so.1
#COPY --from=fpm-extension /usr/lib64/libattr.so.1 /opt/lib/libattr.so.1
#COPY --from=fpm-extension /usr/lib64/libcap.so.2 /opt/lib/libcap.so.2
#COPY --from=fpm-extension /usr/lib64/libelf.so.1 /opt/lib/libelf.so.1
#COPY --from=fpm-extension /usr/lib64/libbz2.so.1 /opt/lib/libbz2.so.1

COPY common/fpm/bref.ini /opt/bref/etc/php/conf.d/
COPY common/fpm/bref-extensions.ini /opt/bref/etc/php/conf.d/

COPY common/fpm/bootstrap.sh /opt/bootstrap
# Copy files to /var/runtime to support deploying as a Docker image
COPY common/fpm/bootstrap.sh /var/runtime/bootstrap
RUN chmod +x /opt/bootstrap && chmod +x /var/runtime/bootstrap

COPY common/fpm/php-fpm.conf /opt/bref/etc/php-fpm.conf

COPY --from=bref/fpm-internal-src /opt/php-fpm-runtime /opt/php-fpm-runtime

COPY tests/test_5_fpm_handler.php /var/task/test_5_fpm_handler.php
COPY tests/test_5_fpm_invocation.php /opt/tests/test_5_fpm_invocation.php

FROM alpine:3.14 as zip-fpm

RUN apk add zip

COPY --from=fpm /opt /opt

RUN rm /opt/tests -rf && rm /var/task/test_5_fpm_handler.php -f

WORKDIR /opt

RUN zip --quiet --recurse-paths /tmp/layer.zip .
