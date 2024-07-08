#!/bin/bash

# Exit script if the command fails
set -eu

help() {
  echo "Use command: tag"
  exit 1
}
[[ $# -eq 0 ]] && help

option="${1}"

case "$option" in
  "tag")
    # UTC time
    # date=$(date '+%Y%m%d.%H%M')
    # IST time
    date=$(date --date='+5 hour 30 minutes' '+%Y%m%d.%H%M')
    GIT_TAG=v${date}-lw
    git tag ${GIT_TAG}
    git push origin --tags
  ;;
  *)
    help
  ;;
esac