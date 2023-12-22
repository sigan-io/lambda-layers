#!/bin/sh

# Fail on error
set -e

echo "[INFO] Bootstrap started."

# Start the runtime on a loop to keep the container running
while true; do
    php "/opt/bref/bootstrap.php" 2>&1
done
