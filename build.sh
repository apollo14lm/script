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
    GIT_TAG=${2:-}
    if [ -z "$GIT_TAG" ]; then
      # check if the current commit already has a tag
      EXISTING_TAG=$(git describe --tags --exact-match 2>/dev/null || true)
      if [ -n "$EXISTING_TAG" ]; then
        GIT_TAG=$EXISTING_TAG
        echo "Using existing tag for current commit: $GIT_TAG"
      else
        # use current date and time in IST (Indian Standard Time)
        DATE_FMT=$(TZ='Asia/Kolkata' date '+%Y%m%d.%H%M')

        GIT_TAG=v${DATE_FMT}-lw
      fi
    fi

    # Create tag if it doesn't already exist locally
    if [ "$(git tag -l "$GIT_TAG")" != "$GIT_TAG" ]; then
      git tag ${GIT_TAG}
    fi
    git push origin ${GIT_TAG}
  ;;
  *)
    help
  ;;
esac
