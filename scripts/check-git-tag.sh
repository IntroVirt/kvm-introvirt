#!/bin/bash

# Run from the root of the repo. Checks a tag ($1) to see if it's a valid thing to clone from the Ubuntu kernel source
# Used as a helper when saving the kernel tag file for Ubuntu releases.
# Specify LSB_CODENAME or it defaults to this system's

_LSB_CODENAME=${LSB_CODENAME:=$(lsb_release -cs 2> /dev/null)}

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <tag-to-check>"
    exit 1
fi

echo "Codename: ${_LSB_CODENAME}"
repo_url="git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/${_LSB_CODENAME}"
kernel_tag="$1"
echo "Checking ${kernel_tag}"

if ! matches=$(git ls-remote --exit-code --heads --tags "${repo_url}" \
    "refs/heads/${kernel_tag}" \
    "refs/tags/${kernel_tag}"); then
    echo "${kernel_tag} does not exist on ${repo_url}."
    exit 1
fi

echo "${matches}"
echo "Found. git clone --depth 1 --branch \"${kernel_tag}\" will work."
exit 0
