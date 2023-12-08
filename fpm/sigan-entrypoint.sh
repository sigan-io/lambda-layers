#!/bin/sh

echo "Entrypoint: /sigan-entrypoint.sh"

if [ -z "$1" ]; then
    echo "Sigan: No handler provided"
    export _HANDLER=""
else
    export _HANDLER="$1"
fi

if [ -z "$RUNTIME_ENTRYPOINT" ]; then
    export RUNTIME_ENTRYPOINT=/var/runtime/bootstrap
fi

exec "/usr/local/bin/aws-lambda-rie" "$RUNTIME_ENTRYPOINT" "$_HANDLER"
