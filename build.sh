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
    # Mask bucket name in GitHub Actions logs
    if [ -n "${GITHUB_ACTIONS:-}" ]; then
      echo "::add-mask::${BUCKET_PROJECT:-}"
      echo "::add-mask::${BUCKET_ARTIFACT:-}"
    fi

    if [[ -z "${BUCKET_PROJECT:-}" || -z "${SOURCE_FILE:-}" ]]; then
      echo "Error: BUCKET_PROJECT and SOURCE_FILE environment variables must be set for 'src' command."
      exit 1
    fi
    aws s3 cp s3://${BUCKET_PROJECT}/build/${SOURCE_FILE} ./
    SOURCE_DIR=${SOURCE_FILE/.zip/}
    SOURCE_DIR=${SOURCE_DIR/.tar.gz/}
    if [[ "$SOURCE_FILE" == *.tar.gz ]]; then
      mkdir -p ./${SOURCE_DIR}
      tar -xzf ./${SOURCE_FILE} -C ./${SOURCE_DIR}
    else
      unzip -qq ./${SOURCE_FILE} -d ./${SOURCE_DIR}
    fi
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