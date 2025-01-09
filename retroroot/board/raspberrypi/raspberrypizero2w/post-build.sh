#!/usr/bin/env bash
set -ue
BOARD_DIR="$(realpath "$(dirname "$0")")"
source "${BOARD_DIR}"/../common/post-build-include
source "${BOARD_DIR}"/../../common/post-build-include

main(){
  parse_args "${@}"
  add_tty
  setup_mender
}

main "${@}"
