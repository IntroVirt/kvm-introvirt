#!/usr/bin/env bash
set -eu

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DIR=$(realpath $DIR/../patches/ubuntu)

touch $DIR/bionic/available-headers.txt
touch $DIR/focal/available-headers.txt

docker run -v $DIR:/opt --rm -it ubuntu:18.04 /bin/bash -c "apt-get update -y -qq && apt-cache search --names-only '^linux-headers-.*-generic' | sed -e 's/linux-headers-\(.*\)-generic .*/\1/' | sort -V > /opt/bionic/available-headers.txt"
docker run -v $DIR:/opt --rm -it ubuntu:20.04 /bin/bash -c "apt-get update -y -qq && apt-cache search --names-only '^linux-headers-.*-generic' | sed -e 's/linux-headers-\(.*\)-generic .*/\1/' | sort -V > /opt/focal/available-headers.txt"
