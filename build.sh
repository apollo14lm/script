#!/usr/bin/env bash

# -e: Exit immediately if any command fails.
# -u: Treat unset variables as an error.
set -eu

help() {
  echo "Usage: $0 <command> [options]"
  echo "Commands: src | tag"
  exit 0
}
[[ $# -eq 0 ]] && help

ARG1="${1}"

case "$ARG1" in
  src)
    aws s3 cp s3://${BUCKET_NAME}/${SOURCE_FILE} ./
    unzip -qq ./${SOURCE_FILE}
    SOURCE_DIR=${SOURCE_FILE/.zip/}
    SOURCE_DIR=${SOURCE_DIR/.tar.gz/}
    cd ./${SOURCE_DIR}
    ./build.sh ${@:2}
  ;;
  tag)
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