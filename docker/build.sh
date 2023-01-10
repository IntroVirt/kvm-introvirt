#!/usr/bin/env bash
set -eu

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DOCKER_BUILDKIT=1 docker build --build-arg BASE_IMAGE=ubuntu:18.04 -t kvm-introvirt_bionic - < $DIR/ubuntu/Dockerfile
DOCKER_BUILDKIT=1 docker build --build-arg BASE_IMAGE=ubuntu:20.04 -t kvm-introvirt_focal - < $DIR/ubuntu/Dockerfile
DOCKER_BUILDKIT=1 docker build --build-arg BASE_IMAGE=ubuntu:22.04 -t kvm-introvirt_jammy - < $DIR/ubuntu/Dockerfile
