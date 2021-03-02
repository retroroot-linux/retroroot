FROM ubuntu:focal
LABEL maintainer="Adam Duskett <aduskett@gmail.com>" \
description="Everything needed to build Buildroot in a reproducable manner."

ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ=US/Pacific

RUN set -e; \
  apt-get update; \
  apt-get install -y apt-utils; \
  apt-get upgrade -y; \
  apt-get install -y locales;

RUN set -e; \
  rm -rf /var/lib/apt/lists/*; \
  localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Setup tzdata first as to avoid a dialog requesting tzdata setup.
RUN set -e; \
  apt-get update; \
  apt-get install -y tzdata; \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime; \
  echo $TZ > /etc/timezone;

# Install dependencies
RUN set -e; \
  apt-get update; \
  apt-get upgrade -y; \
  apt-get install -y \
  bash \
  bc \
  bison \
  bzip2 \
  cmake \
  cpio \
  curl \
  dialog \
  expect \
  file \
  flex \
  g++ \
  gcc \
  git \
  lib32z1 \
  make \
  mc \
  mercurial \
  nano \
  ncurses-dev \
  patch \
  python-dev \
  python3-dev \
  python3-pip \
  rsync \
  subversion \
  sudo \
  tar \
  unzip \
  wget \
  gcc-multilib \
  g++-multilib \
  libc6-i386; \
  pip3 install \
  aiohttp==3.7.3 \
  cve==1.0.1 \
  ijson==3.1.3 \
  nose2==0.9.2 \
  pexpect==4.8.0 \
  requests==2.25.1 \
  spdx_lookup==0.3.3; \
  cd /usr/bin/; \
  rm python; \
  ln -s python3 python;

# Set these arguments in the docker-compose.yml file and the docker/env file
# if you wish to change the default values.
# Default values:
# BUILDROOT_USER: br-user
# BUILDROOT_DIR: buildroot
# BUILDROOT_VERSION: If set to git, clone from the repo
# The buildroot source code is extracted to /home/${BUILDROOT_USER}/{BUILDROOT_DIR}
ARG BUILDROOT_USER
ARG BUILDROOT_DIR
ARG BUILDROOT_VERSION=2020.02.11
ARG BUILDROOT_BRANCH=master
ARG UID=1000
ARG GID=1000

# Add the ${BUILDROOT_USER} user, as buildroot should never be built as root.
RUN /bin/bash; \
  set -e; \
  groupadd -r -g ${GID} ${BUILDROOT_USER}; \
  useradd -ms /bin/bash -u ${UID} -g ${GID} ${BUILDROOT_USER}; \
  echo "alias ls='ls --color=auto'" >> /home/${BUILDROOT_USER}/.bashrc; \
  echo "PS1='\u@\H [\w]$ '" >> /home/${BUILDROOT_USER}/.bashrc; \
  chown -R ${BUILDROOT_USER}:${BUILDROOT_USER} /home/${BUILDROOT_USER}; \
  if [ $BUILDROOT_VERSION = "git" ]; then \
    echo "Cloning Buildroot on branch ${BUILDROOT_BRANCH}"; \
    git clone git://git.buildroot.net/buildroot /home/${BUILDROOT_USER}/buildroot -b ${BUILDROOT_BRANCH}; \
  else \
    wget https://buildroot.org/downloads/buildroot-${BUILDROOT_VERSION}.tar.bz2 -O /home/${BUILDROOT_USER}/buildroot.tar.bz2; \
    mkdir -p /home/${BUILDROOT_USER}/${BUILDROOT_DIR}; \
    tar -jxf /home/${BUILDROOT_USER}/buildroot.tar.bz2 --strip-components=1 -C /home/${BUILDROOT_USER}/${BUILDROOT_DIR}; \
    rm -rf /home/${BUILDROOT_USER}/buildroot.tar.bz2; \
  fi; \
  chown -R ${BUILDROOT_USER}:${BUILDROOT_USER} /home/${BUILDROOT_USER}/${BUILDROOT_DIR};

# Copy brmake to /usr/bin for non-verbose builds.
WORKDIR /home/${BUILDROOT_USER}/${BUILDROOT_DIR}
RUN set -e; \
  cp utils/brmake /usr/bin/brmake; \
  chmod +x /usr/bin/brmake;

# Perform the following:
# - Pre-emtpively create the ccache diretory for permission purposes.
# - Link each external_tree to the base buildroot directory.
ARG EXTERNAL_TREES
RUN set -e; \
  mkdir -p /home/${BUILDROOT_USER}/ccache; \
  chown -R ${BUILDROOT_USER}:${BUILDROOT_USER} /home/${BUILDROOT_USER}/ccache; \
  mkdir -p /tmp/patches; \
  for tree in ${EXTERNAL_TREES}; do \
    ln -sf /mnt/${tree} ${tree}; \
  done;

# Ensure that any patches held in ${external_trees}/patches/buildroot are applied.
# This ensures that relevant upstream patches cherry-picked from
# https://patchwork.ozlabs.org/project/buildroot/list/ are applied during the
# docker build process.
ARG BUILDROOT_PATCH_DIR
COPY ${BUILDROOT_PATCH_DIR}* /tmp/patches/
RUN set -e; \
  cd  /home/${BUILDROOT_USER}/${BUILDROOT_DIR}; \
  if [ -n "${BUILDROOT_PATCH_DIR}" ]; then \
    for i in $(find /tmp/patches/ -name "*.patch" -exec readlink -f {} \; ); do patch -p1 < "${i}"; done; \
  fi; \
  rm -rf ${BUILDROOT_PATCH_DIR};

COPY --chown=${BUILDROOT_USER}:${BUILDROOT_USER} docker/init /init

USER ${BUILDROOT_USER}
ENV HOME /home/${BUILDROOT_USER}
WORKDIR /home/${BUILDROOT_USER}/${BUILDROOT_DIR}

ENTRYPOINT ["/init"]
CMD ["/bin/bash"]

