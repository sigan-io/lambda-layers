#!/bin/sh

echo "Entrypoint: /wp-php-entrypoint.sh"

if [ -z "$1" ]; then
    echo "WP-PHP: No handler provided"
    export _HANDLER=""
else
    export _HANDLER="$1"
fi

if [ -z "$RUNTIME_ENTRYPOINT" ]; then
    export RUNTIME_ENTRYPOINT=/opt/bootstrap
fi

exec "/usr/local/bin/aws-lambda-rie" "$RUNTIME_ENTRYPOINT" "$_HANDLER"
