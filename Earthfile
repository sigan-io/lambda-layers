VERSION 0.7
FROM public.ecr.aws/lambda/provided:al2023-arm64

ARG --global BUILD_DIR="/tmp/build"
ARG --global INSTALL_DIR="/opt"

ARG --global PKG_CONFIG_PATH="${INSTALL_DIR}/lib64/pkgconfig:${INSTALL_DIR}/lib/pkgconfig"
ARG --global PKG_CONFIG="/usr/bin/pkg-config"
ARG --global PATH="${INSTALL_DIR}/bin:${PATH}"
ARG --global LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

ARG --global CMAKE_BUILD_PARALLEL_LEVEL=4
ARG --global MAKEFLAGS='-j4'

# --------------------------------------------------------------- #
# Builds an image for AWS's WP-PHP custom runtime.
# --------------------------------------------------------------- #
wp-php:
    # Move the layer content to /opt, which is the lambda dir for layers.
    COPY +layer-content/* /opt/
    
    # Entrypoint file used by RIE when running as Docker image.
    COPY wp-php/wp-php-entrypoint.sh    /wp-php-entrypoint.sh

    RUN chmod +x /wp-php-entrypoint.sh

    # We override the entrypoint to pass the lambda handler as an argument.
    ENTRYPOINT ["/wp-php-entrypoint.sh"]

    EXPOSE 8080

    SAVE IMAGE --push siganio/wp-php-82:0.1.0 
    SAVE IMAGE --push siganio/wp-php-82:latest

# --------------------------------------------------------------- #
# Builds a development image for AWS's WP-PHP custom runtime.
# --------------------------------------------------------------- #
wp-php-dev:
    # Move the layer content to /opt, which is the lambda dir for layers.
    COPY (+layer-content/* --DEV=true) /opt/

    # Entrypoint file used by RIE when running as Docker image.
    COPY wp-php/wp-php-entrypoint.sh    /wp-php-entrypoint.sh

    RUN chmod +x /wp-php-entrypoint.sh

    ENV PHP_INI_SCAN_DIR="/opt/bref/etc/php/conf.d:/var/task/php/conf.d:/var/task/php/conf.dev.d"

    # We override the entrypoint to pass the lambda handler as an argument.
    ENTRYPOINT ["/wp-php-entrypoint.sh"]

    EXPOSE 8080

    SAVE IMAGE --push siganio/wp-php-82:0.1.0-dev
    SAVE IMAGE --push siganio/wp-php-82:latest-dev

# --------------------------------------------------------------- #
# Publishes the WP-PHP runtime layer to AWS Lambda.
# --------------------------------------------------------------- #
wp-php-layer:
    WORKDIR ${BUILD_DIR}

    # Install zip libraries needed to zip the layer and install AWS CLI.
    RUN LD_LIBRARY_PATH= dnf install -y zip
    RUN LD_LIBRARY_PATH= dnf install -y unzip
    RUN LD_LIBRARY_PATH= dnf install -y less

    WORKDIR ${BUILD_DIR}/awscli/

    # Install AWS CLI.
    RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
    RUN unzip -qo awscliv2.zip
    RUN ./aws/install

    WORKDIR ${BUILD_DIR}/layer/

    # Copy runtime files.
    COPY +layer-content/* .

    ARG LAYER_NAME=wp-php

    # Zip the layer files to upload them.
    RUN zip --quiet --recurse-paths "$LAYER_NAME.zip" .

    # Start publishing the layer.
    # (Version and Layer Version ARN are outputed to files because
    # env variables are not scoped outside the current command)
    RUN --secret AWS_REGION \
        --secret AWS_ACCESS_KEY_ID \
        --secret AWS_SECRET_ACCESS_KEY \
        read -ra VALUES <<< $(aws lambda publish-layer-version \
        --layer-name $LAYER_NAME \
        --description "Bref PHP Runtime optimized for WordPress" \
        --license-info MIT \
        --zip-file fileb://./$LAYER_NAME.zip \
        --compatible-runtimes provided.al2023 \
        --compatible-architectures arm64 \
        --query "[Version, LayerVersionArn]" \
        --output text) \
        && echo "${VALUES[0]}" > LAYER_VERSION \
        && echo "${VALUES[1]}" > LAYER_VERSION_ARN

    # Set layer permissions to be publicly accessible.
    RUN --secret AWS_REGION \
        --secret AWS_ACCESS_KEY_ID \
        --secret AWS_SECRET_ACCESS_KEY \
        aws lambda add-layer-version-permission \
        --layer-name $LAYER_NAME \
        --version-number $(cat LAYER_VERSION) \
        --statement-id public \
        --principal "*" \
        --action lambda:GetLayerVersion \
        > /dev/null 2>&1

    RUN echo -e "\n\e[36mLayer Name:\e[0m $LAYER_NAME\n\n\e[36mLayer Version:\e[0m $(cat LAYER_VERSION)\n\n\e[36mLayer Version ARN:\e[0m $(cat LAYER_VERSION_ARN)\n"

# --------------------------------------------------------------- #
# Installs all the needed dependencies to build and install PHP.
# --------------------------------------------------------------- #
packages:
    RUN set -xe \
        && dnf makecache

    RUN LD_LIBRARY_PATH= dnf install -y cmake3
    RUN LD_LIBRARY_PATH= dnf install -y gcc
    RUN LD_LIBRARY_PATH= dnf install -y glibc-langpack-en
    RUN LD_LIBRARY_PATH= dnf install -y perl
    RUN LD_LIBRARY_PATH= dnf install -y perl-IPC-Cmd
    RUN LD_LIBRARY_PATH= dnf install -y tar
    RUN LD_LIBRARY_PATH= dnf install -y gzip
    RUN LD_LIBRARY_PATH= dnf install -y xz
    RUN LD_LIBRARY_PATH= dnf install -y zlib
    RUN LD_LIBRARY_PATH= dnf install -y libtool
    RUN LD_LIBRARY_PATH= dnf install -y ImageMagick
    RUN LD_LIBRARY_PATH= dnf install -y ghostscript

    RUN LD_LIBRARY_PATH= dnf install -y libcurl-devel
    RUN LD_LIBRARY_PATH= dnf install -y libicu-devel
    RUN LD_LIBRARY_PATH= dnf install -y libxslt-devel
    RUN LD_LIBRARY_PATH= dnf install -y ImageMagick-devel

# --------------------------------------------------------------- #
# Builds and installs zlib.
# We compile a newer version because Lambda uses an old version
# (1.2.7) that has a security vulnerability (CVE-2022-37434).
# (Check if this issue persists in al2023)
# --------------------------------------------------------------- #
zlib:
    FROM +packages

    ARG VERSION_ZLIB=1.3

    WORKDIR ${BUILD_DIR}/zlib/

    RUN set -xe \
        && curl -Ls https://github.com/madler/zlib/releases/download/v${VERSION_ZLIB}/zlib-${VERSION_ZLIB}.tar.gz \
        | tar xzC . --strip-components=1

    RUN set -xe \
        && make distclean \
        && CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./configure \
        --prefix=${INSTALL_DIR}

    RUN set -xe \
        && make install \
        && rm ${INSTALL_DIR}/lib/libz.a

# --------------------------------------------------------------- #
# Builds and installs openssl
# Releases: https://github.com/openssl/openssl/releases
# Needs:
#   - zlib
# Needed by:
#   - curl
#   - php
# --------------------------------------------------------------- #
openssl:
    FROM +zlib

    ARG VERSION_OPENSSL=3.1.4
    ARG CA_BUNDLE_SOURCE="https://curl.se/ca/cacert.pem"
    ARG CA_BUNDLE="${INSTALL_DIR}/bref/ssl/cert.pem"

    WORKDIR  ${BUILD_DIR}/openssl/

    RUN set -xe \
        && curl -Ls https://github.com/openssl/openssl/releases/download/openssl-${VERSION_OPENSSL}/openssl-${VERSION_OPENSSL}.tar.gz \
        | tar xzC . --strip-components=1

    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./config \
        --prefix=${INSTALL_DIR} \
        --openssldir=${INSTALL_DIR}/bref/ssl \
        --release \
        enable-tls1_3 \
        no-tests \
        shared \
        zlib

    # Explicitly compile make without parallelism because it fails if we use -jX (no error message)
    # I'm not 100% sure why, and I already lost 4 hours on this, but I found this:
    # https://github.com/openssl/openssl/issues/9931
    # https://stackoverflow.com/questions/28639207/why-cant-i-compile-openssl-with-multiple-threads-make-j3
    # Run `make install_sw install_ssldirs` instead of `make install` to skip installing man pages https://github.com/openssl/openssl/issues/8170
    RUN make -j1 install_sw install_ssldirs
    RUN mkdir -p ${INSTALL_DIR}/bref/ssl && curl -Lk -o ${CA_BUNDLE} ${CA_BUNDLE_SOURCE}

# --------------------------------------------------------------- #
# Builds and installs libxml2
# Releases: https://github.com/GNOME/libxml2/releases
# Needs:
#   - zlib
# Needed by:
#   - php
#   - libnghttp2
# --------------------------------------------------------------- #
libxml2:
    FROM +openssl

    ARG VERSION_XML2=2.11.5

    WORKDIR  ${BUILD_DIR}/xml2/

    RUN set -xe \
        && curl -Ls https://download.gnome.org/sources/libxml2/${VERSION_XML2%.*}/libxml2-${VERSION_XML2}.tar.xz \
        | tar xJC . --strip-components=1

    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./configure \
        --prefix=${INSTALL_DIR} \
        --with-sysroot=${INSTALL_DIR} \
        --enable-shared \
        --disable-static \
        --with-html \
        --with-history \
        --enable-ipv6=no \
        --with-icu \
        --with-zlib \
        --without-python

    RUN make install
    RUN cp xml2-config ${INSTALL_DIR}/bin/xml2-config

# --------------------------------------------------------------- #
# Builds and installs libssh2.
# Releases: https://github.com/libssh2/libssh2/releases
# Needs:
#   - zlib
#   - OpenSSL
# Needed by:
#   - curl
# --------------------------------------------------------------- #
libssh2:
    FROM +libxml2

    ARG VERSION_LIBSSH2=1.11.0

    WORKDIR  ${BUILD_DIR}/libssh2/

    RUN set -xe \
        && curl -Ls https://github.com/libssh2/libssh2/releases/download/libssh2-${VERSION_LIBSSH2}/libssh2-${VERSION_LIBSSH2}.tar.gz \
        | tar xzC . --strip-components=1


    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        cmake \
        # Build as a shared library (.so) instead of a static one
        -DBUILD_SHARED_LIBS=ON \
        # Build with OpenSSL support
        -DCRYPTO_BACKEND=OpenSSL \
        # Build with zlib support
        -DENABLE_ZLIB_COMPRESSION=ON \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DCMAKE_BUILD_TYPE=RELEASE

    RUN cmake  --build . --target install


# --------------------------------------------------------------- #
# Builds and installs libnghttp2.
# Releases: https://github.com/nghttp2/nghttp2/releases
# Needs:
#   - zlib
#   - OpenSSL
#   - libxml2
# Needed by:
#   - curl
# --------------------------------------------------------------- #
libnghttp2:
    FROM +libssh2

    ARG VERSION_NGHTTP2=1.58.0

    WORKDIR  ${BUILD_DIR}/nghttp2

    RUN set -xe \
        && curl -Ls https://github.com/nghttp2/nghttp2/releases/download/v${VERSION_NGHTTP2}/nghttp2-${VERSION_NGHTTP2}.tar.gz \
        | tar xzC . --strip-components=1

    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./configure \
        --enable-lib-only \
        --prefix=${INSTALL_DIR}

    RUN make install

# --------------------------------------------------------------- #
# Builds and installs curl. (NOT USED)
# Releases: https://github.com/curl/curl/releases
# Needs:
#   - zlib
#   - OpenSSL
#   - libssh2
#   - libnghttp2
# Needed by:
#   - php
# --------------------------------------------------------------- #
curl:
    FROM +libnghttp2

    ARG VERSION_CURL=8.4.0

    WORKDIR  ${BUILD_DIR}/curl/

    RUN set -xe \
        && curl -Ls https://github.com/curl/curl/archive/curl-${VERSION_CURL//./_}.tar.gz \
        | tar xzC . --strip-components=1


    RUN ./buildconf
    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./configure \
        --prefix=${INSTALL_DIR} \
        --with-ca-bundle=${CA_BUNDLE} \
        --enable-shared \
        --disable-static \
        --enable-optimize \
        --disable-warnings \
        --disable-dependency-tracking \
        --with-zlib \
        --enable-http \
        --enable-ftp  \
        --enable-file \
        --enable-proxy  \
        --enable-tftp \
        --enable-ipv6 \
        --enable-openssl-auto-load-config \
        --enable-cookies \
        --with-gnu-ld \
        --with-ssl \
        --with-libssh2 \
        --with-nghttp2

    RUN make install

# --------------------------------------------------------------- #
# Builds and installs libzip.
# Releases: https://github.com/nih-at/libzip/releases
# Needed by:
#   - php
# --------------------------------------------------------------- #
libzip:
    FROM +libnghttp2

    ARG VERSION_ZIP=1.10.1

    WORKDIR  ${BUILD_DIR}/zip/

    RUN set -xe \
        && curl -Ls https://github.com/nih-at/libzip/releases/download/v${VERSION_ZIP}/libzip-${VERSION_ZIP}.tar.gz \
        | tar xzC . --strip-components=1


    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        cmake \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
        -DCMAKE_BUILD_TYPE=RELEASE

    RUN cmake  --build . --target install

# --------------------------------------------------------------- #
# Builds and installs libsodium.
# Releases: https://github.com/jedisct1/libsodium/releases
# Needed by:
#   - php
# --------------------------------------------------------------- #
libsodium:
    FROM +libzip

    ARG VERSION_LIBSODIUM=1.0.19

    WORKDIR  ${BUILD_DIR}/libsodium/

    RUN set -xe \
        && curl -Ls https://github.com/jedisct1/libsodium/archive/${VERSION_LIBSODIUM}.tar.gz \
        | tar xzC . --strip-components=1

    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./autogen.sh \
        && ./configure \
        --prefix=${INSTALL_DIR}

    RUN make install

# --------------------------------------------------------------- #
# Builds and installs Postgres. (NOT USED)
# Releases: https://github.com/postgres/postgres/releases
# Needs:
#   - OpenSSL
# Needed by:
#   - php
# --------------------------------------------------------------- #
postgres:
    FROM +libsodium

    ARG VERSION_POSTGRES=15.5

    WORKDIR  ${BUILD_DIR}/postgres/

    RUN set -xe \
        && curl -Ls https://github.com/postgres/postgres/archive/REL_${VERSION_POSTGRES//./_}.tar.gz \
        | tar xzC . --strip-components=1


    RUN CFLAGS="" \
        CPPFLAGS="-I${INSTALL_DIR}/include -I/usr/include" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
        ./configure \
        --prefix=${INSTALL_DIR} \
        --with-openssl \
        --without-readline
    RUN cd src/interfaces/libpq && make && make install
    RUN cd src/bin/pg_config && make && make install
    RUN cd src/backend && make generated-headers
    RUN cd src/include && make install

# --------------------------------------------------------------- #
# Builds and installs libsodium.
# (TODO: Maybe this build is not needed. We need to try to install it with dnf)
# Releases: https://github.com/kkos/oniguruma/releases
# Needed by:
#   - mbstring
# --------------------------------------------------------------- #
oniguruma:
    FROM +libsodium

    ARG VERSION_ONIG=6.9.9

    WORKDIR  ${BUILD_DIR}/oniguruma/

    RUN set -xe \
        && curl -Ls https://github.com/kkos/oniguruma/releases/download/v${VERSION_ONIG}/onig-${VERSION_ONIG}.tar.gz \
        | tar xzC . --strip-components=1


    RUN ./configure \
        --prefix=${INSTALL_DIR}
    RUN make
    RUN make install

# --------------------------------------------------------------- #
# Installs PHP and exports PHP-FPM.
# --------------------------------------------------------------- #
php-install:
    FROM +oniguruma

    ARG VERSION_PHP=8.2.12

    WORKDIR ${BUILD_DIR}/php/

    RUN curl --location --silent --show-error --fail https://www.php.net/get/php-${VERSION_PHP}.tar.gz/from/this/mirror \
        | tar xzC . --strip-components=1

    # Configure the build
    # -fstack-protector-strong : Be paranoid about stack overflows
    # -fpic : Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
    # -fpie : Support Address Space Layout Randomization (see -fpic)
    # -O3 : Optimize for fastest binaries possible.
    # -I : Add the path to the list of directories to be searched for header files during preprocessing.
    # --enable-option-checking=fatal: make sure invalid --configure-flags are fatal errors instead of just warnings
    RUN ./buildconf --force
    RUN CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -I${INSTALL_DIR}/include -I/usr/include -ffunction-sections -fdata-sections" \
        CPPFLAGS="-fstack-protector-strong -fpic -fpie -O3 -I${INSTALL_DIR}/include -I/usr/include -ffunction-sections -fdata-sections" \
        LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib -Wl,-O1 -Wl,--strip-all -Wl,--hash-style=both -pie" \
        ./configure \
        --prefix=${INSTALL_DIR} \
        --enable-option-checking=fatal \
        --with-config-file-path=/opt/bref/etc/php \
        --with-config-file-scan-dir=/opt/bref/etc/php/conf.d:/var/task/php/conf.d \
        # Required by WP
        --enable-exif \
        --enable-mbstring \
        --enable-xml \
        --enable-fileinfo \
        --enable-bcmath \
        --enable-filter \
        --enable-shmop \
        --enable-opcache \
        --enable-intl=shared \
        --with-zip=shared \
        --with-curl=shared \
        --with-openssl=shared \
        --with-mysqli=shared \
        --with-iconv=shared \
        --with-sodium=shared \
        --with-xsl=shared \
        # Not required by WP or AWS Lambda
        --disable-pdo \
        --disable-cgi \
        --without-sqlite3 \
        # Binaries
        --enable-fpm \
        --enable-cli
    RUN make -j $(nproc)
    RUN make install
    RUN make clean

    # This php.ini is to be used in the build, but it's not going to the image.
    RUN mkdir -p ${INSTALL_DIR}/etc/php/ \
        && cp php.ini-production ${INSTALL_DIR}/etc/php/php.ini

    SAVE ARTIFACT ${INSTALL_DIR}/bin/php        php
    SAVE ARTIFACT ${INSTALL_DIR}/sbin/php-fpm   php-fpm

# --------------------------------------------------------------- #
# Builds the APCu extension for PHP and exports it.
# --------------------------------------------------------------- #
php-apcu:
    FROM +php-install

    WORKDIR ${BUILD_DIR}/apcu/

    RUN set -xe \
        && curl -Ls https://pecl.php.net/get/APCu \
        | tar -xzC . --strip-components=1
    
    RUN phpize
    RUN ./configure --enable-apcu
    RUN make

    SAVE ARTIFACT modules/apcu.so

# --------------------------------------------------------------- #
# Builds the Imagick extension for PHP and exports it.
# --------------------------------------------------------------- #
php-imagick:
    FROM +php-install

    WORKDIR ${BUILD_DIR}/imagick/

    RUN set -xe \
        && curl -Ls https://pecl.php.net/get/imagick \
        | tar -xzC . --strip-components=1

    RUN phpize
    RUN ./configure
    RUN make

    SAVE ARTIFACT modules/imagick.so

# --------------------------------------------------------------- #
# Builds the igbinary extension for PHP and exports it.
# --------------------------------------------------------------- #
php-igbinary:
    FROM +php-install

    WORKDIR ${BUILD_DIR}/igbinary/

    RUN set -xe \
        && curl -Ls https://pecl.php.net/get/igbinary \
        | tar -xzC . --strip-components=1

    RUN phpize
    RUN ./configure \
        CFLAGS="-O2 -g" \
        --enable-igbinary
    RUN make

    SAVE ARTIFACT modules/igbinary.so

# --------------------------------------------------------------- #
# Builds the igbinary extension for PHP and exports it.
# --------------------------------------------------------------- #
php-xdebug:
    FROM +php-install

    WORKDIR ${BUILD_DIR}/xdebug/

    RUN set -xe \
        && curl -Ls https://pecl.php.net/get/xdebug \
        | tar -xzC . --strip-components=1

    RUN phpize
    RUN ./configure \
        --enable-xdebug
    RUN make

    SAVE ARTIFACT modules/xdebug.so

# --------------------------------------------------------------- #
# Groups all PHP extensions in one place and exports them.
# --------------------------------------------------------------- #
php-extensions:
    FROM +php-install

    WORKDIR ${BUILD_DIR}/extensions/

    ARG PHP_EXT_DIR=$(php -r 'echo ini_get("extension_dir");')
    
    # Get all extensions in one place.
    RUN cp ${PHP_EXT_DIR}/* .
    COPY +php-apcu/*        .
    COPY +php-imagick/*     .
    COPY +php-igbinary/*    .

    # Export PHP extensions.
    SAVE ARTIFACT .

# --------------------------------------------------------------- #
# Generates a list of all the libraries installed by default.
# --------------------------------------------------------------- #
al2023-libraries:
    WORKDIR ${BUILD_DIR}

    RUN ls -p /lib64/ | grep -v / | sort > al2023-libraries.txt

    SAVE ARTIFACT al2023-libraries.txt

# --------------------------------------------------------------- #
# Puts together the needed dependencies for PHP and exports them.
# --------------------------------------------------------------- #
php-dependencies:
    FROM +php-install

    WORKDIR ${BUILD_DIR}/dependencies/

    RUN mkdir extensions
    RUN mkdir libraries

    WAIT
        BUILD +php-extensions
    END

    # Get all extensions.
    COPY +php-extensions/* ./extensions/

    # Get necessary files to filter dependencies.
    COPY utils/copy-dependencies .
    COPY +al2023-libraries/* .

    # Get dependencies of PHP.
    RUN ./copy-dependencies ${INSTALL_DIR}/bin/php        ./libraries al2023-libraries.txt

    # Get dependencies of PHP-FPM.
    RUN ./copy-dependencies ${INSTALL_DIR}/sbin/php-fpm   ./libraries al2023-libraries.txt

    # Get dependencies of PHP extensions.
    FOR extension IN $(ls extensions)
        RUN ./copy-dependencies "./extensions/${extension}" ./libraries al2023-libraries.txt
    END

    # Export PHP dependencies.
    SAVE ARTIFACT libraries/*

# --------------------------------------------------------------- #
# Puts together the layer content for the custom runtime.
# --------------------------------------------------------------- #
layer-content:
    WORKDIR ${BUILD_DIR}/layer-content/

    # Set environment variable to conditionally install dev extensions (i.e. xdebug).
    ARG DEV=false

    # Directory for AWS Lambda Extensions (to prevent a warning when starting runtime).
    RUN mkdir                           ./extensions

    # Copy layer files to /opt, which is the dir lambda uses for layers.
    COPY +php-install/php               ./bin/php
    COPY +php-install/php-fpm           ./bin/php-fpm
    COPY +php-extensions/*              ./bref/extensions/
    COPY +php-dependencies/*            ./lib/
    COPY wp-php/php-fpm.ini             ./bref/etc/php/conf.d/php-fpm.ini
    COPY wp-php/php-fpm.conf            ./bref/etc/php-fpm.conf
    COPY wp-php/bootstrap.php           ./bref/bootstrap.php
    COPY wp-php/bootstrap.sh            ./bootstrap

    IF [ "$DEV" = true ]
        COPY +php-xdebug/*              ./bref/extensions/
    END

    RUN chmod +x ./bootstrap

    SAVE ARTIFACT .
