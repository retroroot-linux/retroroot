#!/usr/bin/env bash
set -e
BOARD_DIR="$(realpath $(dirname "$0"))"
GENIMAGE_CFG="${BOARD_DIR}/genimage-efi.cfg"
DATA_PART_SIZE="32M"
DEVICE_TYPE="buildroot-x86_64"
GENERATE_MENDER_IMAGE="false"
ARTIFACT_NAME="1.0"

exit 0
# Parse arguments.
function parse_args(){
    local o O opts
    o='a:o:d:g:'
    O='artifact-name:,data-part-size:,device-type:,generate-mender-image:'
    opts="$(getopt -n "${my_name}" -o "${o}" -l "${O}" -- "${@}")"
    eval set -- "${opts}"
    while [ ${#} -gt 0 ]; do
        case "${1}" in
        (-o|--data-part-size)
            DATA_PART_SIZE="${2}"; shift 2
            ;;
        (-d|--device-type)
            DEVICE_TYPE="${2}"; shift 2
            ;;
        (-g|--generate-mender-image)
            GENERATE_MENDER_IMAGE="${2}"; shift 2
            ;;
        (-a|--artifact-name)
            ARTIFACT_NAME="${2}"; shift 2
            ;;
        (--)
            shift; break
            ;;
        esac
    done
}


function generate_image(){
    sh support/scripts/genimage.sh -c "${BINARIES_DIR}"/genimage-efi.cfg
}


# Main function.
function main(){
  parse_args "${@}"
  generate_image
  exit $?
}

main "${@}"
