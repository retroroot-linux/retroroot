# retroroot

A buildroot based OS used for running retroarch.

### Prerequisites:
  - A computer running Linux (WSL2 is untested but may work!)
  - Docker

## Quick setup
  - Clone this repository:
    - `git clone https://github.com/retroroot-linux/retroroot.git`
  - Build the docker container:
    - `make build`
 - choose the board you want to build by looking in the docker/ directory for .json files. IE: docker/x86_64.json
 - Start the docker container. The build will start automatically. IE:
   - `ENV_FILES=x86_64.json make up`
 - Images are found in `retroroot/images`

## Currently tested boards:
  - x86_64

## Other notes:
  - See docker/env.json.readme for env file options.
  - See `make help` for make file options.
  - `make shell` will skip building and put you into the docker shell. Navigate to `retroroot/output/${config_name}` to build manually.
  - Board files are found in `retroroot/board`
  - Config files are found in `retroroot/configs`
  - Buildroot patches are found in `retroroot/patches/builldroot`
  - After building retroroot_x86_64_KMS_defconfig run `make x64-run` to start the virtual image. Console is found on the serial port.
  - All defconfigs build.
