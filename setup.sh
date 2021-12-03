#!/usr/bin/env bash

set -euo pipefail

declare -r tag="${INPUT_TAG}"

declare -r SRC="$(dirname $(realpath "${BASH_SOURCE[0]}"))"

declare platform=""
case "${RUNNER_OS}" in
  Linux)
    platform="linux64"
    ;;
  macOS)
    platform="macos"
    ;;
  *)
    echo "Unsupported platform: ${RUNNER_OS} ${RUNNER_ARCH}" >&2
    exit 1;
esac

declare -r url="https://github.com/neovim/neovim/releases/download/${tag}/nvim-${platform}.tar.gz"
declare -r filename=$(basename "${url}")

mkdir -p "${SRC}/neovim/.archives"

echo "Downloading archive..."
curl --progress-bar --continue-at - --output "${SRC}/neovim/.archives/${filename}" -L "${url}"

echo "Extracting archive..."
tar --strip-components=1 -xzf "${SRC}/neovim/.archives/${filename}" -C "${SRC}/neovim"

echo "Setting PATH..."
echo "${SRC}/neovim/bin" >> ${GITHUB_PATH}
