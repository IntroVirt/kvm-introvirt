ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN apt-get -qq update \
&& DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
    bc devscripts quilt git flex bison libssl-dev libelf-dev debhelper \
    fakeroot kmod build-essential \
    vim sudo

# Create passwordless user that can sudo
RUN useradd -m user && echo "user:user" | chpasswd && adduser user sudo
RUN echo '%sudo ALL = (ALL) NOPASSWD: ALL' > /etc/sudoers.d/user

RUN chown user:user /opt

USER user

WORKDIR /opt/kvm-introvirt
