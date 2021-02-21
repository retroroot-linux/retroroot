# Overview
This directory contains all necessary directories and files of which to build retroroot.

## Reasons for using containers to build
Containers provide the following:
  - A consistent build environment
  - Easy setup and onboarding
  - Reproducible builds
  - An all-in-one setup process.

## Directory structure
This directory has the following structure:
  - buildroot
    - A stock buildroot download found at [buildroot.org](https://buildroot.org/) 
  - docker
    - Contains two files:
      - env_file
        - This file contains several environment variables used during the init process.
      - init
        - Automatically set's up the buildroot environment on startup and then runs /bin/bash to keep the docker container running.
  - retroroot
    - The retroroot directory contains several directories used for persistent storage purposes.
        - board:
          - Board specific files and directories.
        - configs:
          - Buildroot defconfig files. During the initialization process, the docker init script loops through this directory and applies each config to retroroot/output.
        - dl:
          - This directory contains all downloaded source packages used in the above configs in a compressed format.
        - output:
          - The init-script applies each config file found in retroroot/configs to output/config_name, and then the source code is built in that directory.
        - package:
          - Any external packages not in stock Buildroot go here.
        - production:
          - Once built, production images go here.
  - scripts
    - Various scripts used for development purposes.

## Prerequisites:
- A computer running macOS, Linux, or Windows with WSL2
- Docker
- Python3
- docker-compose
- 10 - 20GB of free space.

## Setup
  - First, set the variables in docker/env to what is appropriate for the build.
    By default, the environment variables automatically apply all config files found in retroroot/configs but does not auto-build them.
  - run `docker-compose build`

## Building
If auto-building:
  - run `docker-compose up`

If manually-building:
  - run `docker-compose up -d && && docker exec -ti buildroot-aws-iot-build /bin/bash`
  - Then navigate to `/home/br-user/buildroot/` and build manually. If `AUTO_CONFIG` is set to 1
    in docker/env, then there are directories automatically created in `/home/br-user/buildroot/aws/output`

# Customizations

## Changing the buildroot user name
  - Edit the BUILDROOT_USER variable in the docker/env and docker-compose.yml files.

## Changing the buildroot UID and GID
  - The default UID and GID for the buildroot user is 1000, however you may customize the default by either:
    - modifying the docker-compose.yml file directly.
    - passing the UID and GID directly from the command line. IE: `docker-compose build --build-arg UID=$(id -u $(whoami)) --build-arg GID=$(id -g $(whoami))`

## Changing the buildroot directory name
  - Edit the BUILDROOT_DIR variable in the docker/env and docker-compose.yml files.

## Adding patches to buildroot
  - Add a directory to the BUILDROOT_PATCH_DIR argument in the docker-compose.yml file.
    Patches are automatically copied and applied to buildroot when `docker-compose build` is ran.

## Adding additional external trees
  - Add additional external trees by copying the aws directory to a new directory and adding the new directories name to the
    EXTERNAL_TREES variable in the docker-compose.yml file nad the docker/env file.
    Both variables are SPACE DELIMITED!

## Changing the Buildroot version
  - Edit the BUILDROOT_VERSION argument in the docker-compose.yml file
  - run `docker-compose build`
  Note: If you have a BUILDROOT_PATCH_DIR defined, watch for failures during the build process to ensure that all patches applied cleanly!

# Using the packages without docker:

- clone or download buildroot from: https://buildroot.org/
- clone or download and extract this repository: `git clone git@github.com:aduskett/buildroot-aws-iot.git`
- copy the config to the buildroot configs directory: `cp buildroot-aws-iot/aws/configs/greengrass_qemu_x86_64_defconfig configs/greengrass_qemu_x86_64_defconfig`
- apply the config with the external tree: `BR2_EXTERNAL=buildroot-aws-iot/aws make greengrass_qemu_x86_64_defconfig`
- Add or remove packages with `make menuconfig`
- Build the project with `make`
- Run the qemu image (see buildroot-aws-iot/aws/board/greengrass-qemu-x86_64/readme.txt)

For more information about using and building with Buildroot, see: https://buildroot.org/downloads/manual/manual.html

## Further reading
Please check [The Buildroot manual](https://buildroot.org/downloads/manual/manual.html) for more information.
