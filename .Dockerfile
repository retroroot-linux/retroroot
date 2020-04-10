FROM centos:8
MAINTAINER Adam Duskett <aduskett@gmail.com>

# Install dependencies
RUN dnf update -y
RUN dnf install -y epel-release
RUN dnf install -y \
  bash \
  bc \
  bison \
  bzip2 \
  cmake \
  cpio \
  curl \
  dialog \
  dwarves \
  expect \
  file \
  flex \
  gcc \
  gcc-c++ \
  git \
  elfutils-libelf-devel \
  make \
  mc \
  nano \
  ncurses-devel \
  patch \
  perl-Data-Dumper \
  perl-ExtUtils-MakeMaker \
  perl-Thread-Queue \
  rsync \
  sudo \
  svn \
  tar \
  unzip \
  wget \
  which \
  xz

# 32bit binaries
RUN set -e; \
  dnf install -y \
  glibc-devel.i686 \
  libgcc.i686 \
  libstdc++-devel.i686 \
  ncurses-devel.i686 \
  zlib.i686 \
  glibc.i686

RUN set -e; \
  dnf install -y python2-pip; \
  pip2 install -U pip --prefix=/usr; \
  pip2 install \
  nose2==0.9.2 \
  pexpect==4.8.0 \
  spdx_lookup==0.3.2;

RUN set -e; \
  dnf install -y python3-pip; \
  ln -s /usr/bin/python3 /usr/bin/python; \
  pip3 install -U pip --prefix=/usr; \
  pip3 install \
  nose2==0.9.2 \
  pexpect==4.8.0 \
  spdx_lookup==0.3.2;

RUN set -e; \
  useradd -ms /bin/bash br-user; \
  echo "alias ls='ls --color=auto'" >> /home/br-user/.bashrc; \
  echo "PS1='\u@\H [\w]$ '" >> /home/br-user/.bashrc;

RUN set -e; \
  chown -R br-user:br-user /home/br-user; \
  echo "alias ls='ls --color=auto'" >> /root/.bashrc; \
  echo "PS1='\u@\H [\w]$ '" >> /root/.bashrc

COPY buildroot /home/br-user/buildroot
WORKDIR /home/br-user/buildroot
RUN set -e; \
  rm -rf configs; \
  ln -s /mnt/retroarch retroarch; \
  ln -s /mnt/retroarch/configs configs; \
  ln -s /mnt/build build; \
  chown -R br-user:br-user /home/br-user;

USER br-user
ENV HOME /home/br-user
ENV LC_ALL en_US.UTF-8

CMD ["/bin/bash"]
