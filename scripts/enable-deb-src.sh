#!/bin/bash

# Helper script to enable deb-src packages
# Run from the root of the repo

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

sed -i '/^#\s*deb-src /s/^# *//' /etc/apt/sources.list
if [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
    sed -Ei 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
fi
apt-get update

exit 0
