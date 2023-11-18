#!/usr/bin/env bash

# Fail on error
set -e

# Ensure CPU_SUFFIX is set
if [ -z "$CPU_SUFFIX" ]; then
    echo "CPU_SUFFIX is not set. Exiting."
    exit 1
fi

output_file="/libs-$CPU_SUFFIX.txt"

for file in /lib64/*; do
    if [ ! -d "$file" ]; then
        basename "$file"
    fi
done | sort >"$output_file"
