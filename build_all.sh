#!/bin/bash
set -eux

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $DIR

# Kernel target, e.g. ubuntu/focal/Ubuntu-5.4.0-135.152
KERNEL_TARGETS=""
# Options are: configure, compile, package, source
PACKAGE_TARGET=compile
# Commands appended in Docker
DOCKER_SHELL_APPEND=""
# DOCKER_SHELL_APPEND=" || bash" # Get an interactive shell in case of an error
# DOCKER_SHELL_APPEND="; bash" # Always get an interactive shell

version_tag() {
    local distro=$1
    local version=$2

    [[ "$distro" = "ubuntu" ]] && echo "Ubuntu-$version"
}

# We support more patches (following kernel tags) than available headers published.
get_all_supported_versions() {
    # TODO: Create new symlink

    # Setup docker images
    $DIR/docker/build.sh

    # Refresh available headers
    $DIR/scripts/docker-update-available-headers.sh

    pushd $DIR/patches > /dev/null
    for distro in *; do
        pushd $distro > /dev/null
        for release in *; do
            pushd $release > /dev/null
            local available_headers=$(cat available-headers.txt)
            for minor in *; do
                [[ $minor = "available-headers.txt" ]] && continue
                pushd $minor > /dev/null
                for version in *; do
                    # Skip HWE for now
                    for avail in $available_headers; do
                        # ${var1%*-*} var1 with everything up to the last '-'
                        if [[ $avail = ${version%*.*} ]]; then
                            echo "$distro/$release/$(version_tag $distro $version)"
                        fi
                    done
                done
                popd > /dev/null
            done
            popd > /dev/null
        done
        popd > /dev/null
    done
    popd > /dev/null
}

get_remote_for_distro() {
    # distro is, for example, in the form of ubuntu/focal
    distro=$1

    case $distro in
    ubuntu/bionic)
        echo https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/bionic
        ;;
    ubuntu/focal)
        echo https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/focal
        ;;
    esac
}

usage() {
    echo "$0 [option...]"
    echo "Builds kvm-introvirt packages. By default builds all the supported kernel versions by default"
    echo "--package-target <target>: [patch|configure|compile|package|source]"
    echo "--kernel-targets <distro/release/tag>: e.g. ubuntu/release/Ubuntu-5.4.0-109.123"
    echo "--all (default): Build all the supported versions."
}

while [ "$#" -gt 0 ]; do
    case "$1" in
    --package-target)
        PACKAGE_TARGET="$2"
        shift 2
        ;;
    --kernel-targets)
        KERNEL_TARGETS="$(echo "$2" | tr ' ' '\n')"
        shift 2
        ;;
    --all)
        KERNEL_TARGETS=$(get_all_supported_versions)
        shift 1
        ;;
    *)
        usage
        exit 1
        ;;
    esac
done

[[ -z $KERNEL_TARGETS ]] && KERNEL_TARGETS=$(get_all_supported_versions)

DISTRO_RELEASES=$(echo "$KERNEL_TARGETS" | sed 's/\(.*\)\/.*/\1/' | sort -u);

# Setup kernel repo for all builds
if [[ -d kernel ]]; then
    [[ ! -d kernel/.git ]] && echo "error: kernel is not a repo" && exit 1

    pushd kernel

    # Verify clean state
    if output=$(git status --porcelain) && [ -z "$output" ]; then
        echo "kernel is clean and pointing to $(git rev-parse --short HEAD)"
    else
        echo "kernel has uncommitted changes, aborting..."
        exit 1
    fi

    # Setup remotes
    for DISTRO_RELEASE in $DISTRO_RELEASES; do
        if [[ "$(git remote get-url $DISTRO_RELEASE)" != "$(get_remote_for_distro $DISTRO_RELEASE)" ]]; then
            echo "Adding remote $DISTRO_RELEASE"
            git remote add $DISTRO_RELEASE "$(get_remote_for_distro $DISTRO_RELEASE)"
        fi
        git fetch $DISTRO_RELEASE
    done

    popd
else
    if [[ $(echo $KERNEL_TARGETS | wc -l) -eq 1 ]]; then
        # configure will shallow clone for us
        :
    else
        DISTRO_RELEASE=$(echo $DISTRO_RELEASES | cut -d ' ' -f 1)
        git clone "$(get_remote_for_distro $DISTRO_RELEASE)" --origin $DISTRO_RELEASE

        DISTRO_RELEASE=$(echo $DISTRO_RELEASES | cut -d ' ' -f 2-)
        for DISTRO_RELEASE in $DISTRO_RELEASES; do
            git remote add $DISTRO_RELEASE "$(get_remote_for_distro $DISTRO_RELEASE)"
            git fetch $DISTRO_RELEASE
        done
    fi
fi

for KV in $KERNEL_TARGETS; do
    echo KV=$KV

    git -C $DIR/debian clean -fdx

    UBUNTU_KERNEL_VERSION=$KV source ./scripts/ubuntu_vars.sh
    git -C $DIR/kernel checkout $KERNEL_TAG -f
    git -C $DIR/kernel reset --hard

    UBUNTU_KERNEL_VERSION=$KV ./configure_ubuntu.sh # Applies patches

    if [[ $PACKAGE_TARGET = configure ]]; then
        # Do nothing, since we already ran: UBUNTU_KERNEL_VERSION=$KV ./configure_ubuntu.sh
        :
    elif [[ "$PACKAGE_TARGET" = "source" ]]; then
        dpkg-buildpackage -us -uc -d --build=source
        mkdir -p $DIR/out
        mv  ../kvm-introvirt_*.tar.xz \
            ../kvm-introvirt_*.dsc \
            ../kvm-introvirt_*_source.buildinfo \
            ../kvm-introvirt_*_source.changes \
            $DIR/out
    elif [[ $PACKAGE_TARGET = compile ]]; then
        if [[ "${DISTRO}" = "ubuntu" ]]; then
            docker run -it --rm -v $PWD:/opt/kvm-introvirt kvm-introvirt_${DISTRO_RELEASE} bash -c "
                sudo apt-get install -y linux-headers-${KERNEL_VERSION}${KERNEL_FLAVOR} linux-modules-${KERNEL_VERSION}${KERNEL_FLAVOR} \
                && cd /opt/kvm-introvirt  \
                && . ./.build_vars \
                && make -j \
                $DOCKER_SHELL_APPEND
            "
                # && export UBUNTU_KERNEL_VERSION=$KV && ./configure_ubuntu.sh \
        fi
    elif [[ $PACKAGE_TARGET = package ]]; then
        if [[ "${DISTRO}" = "ubuntu" ]]; then
            echo UBUNTU_KERNEL_VERSION=$KV
            echo DISTRO_RELEASE=$DISTRO_RELEASE
            echo linux-headers-${KERNEL_VERSION}${KERNEL_FLAVOR} linux-modules-${KERNEL_VERSION}${KERNEL_FLAVOR}

            # docker run -it --rm -v $PWD:/opt/kvm-introvirt kvm-introvirt_${DISTRO_RELEASE}
            docker run -it --rm -v $PWD:/opt/kvm-introvirt kvm-introvirt_${DISTRO_RELEASE} bash -c "
                sudo apt-get install -y linux-headers-${KERNEL_VERSION}${KERNEL_FLAVOR} linux-modules-${KERNEL_VERSION}${KERNEL_FLAVOR} \
                && cd /opt/kvm-introvirt  \
                && dpkg-buildpackage -us -uc --build=any,all -j$(getconf _NPROCESSORS_ONLN) \
                && mkdir -p ./out && mv ../*.deb ./out \
                $DOCKER_SHELL_APPEND
            "
                # && export UBUNTU_KERNEL_VERSION=$KV \
                # && ./configure_ubuntu.sh \
        fi
    fi
done