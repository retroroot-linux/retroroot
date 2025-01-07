#!/usr/bin/env bash
set -e
BOARD_DIR="$(realpath "$(dirname "$0")")"
source "${BOARD_DIR}"/../../common/post-build-include

main(){
  parse_args "${@}"
  setup_mender
}

main "${@}"
