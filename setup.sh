#!/usr/bin/env bash

set -euo pipefail

declare -r tag="${INPUT_TAG}"

declare -r ROOT_DIR="$(dirname $(realpath "${BASH_SOURCE[0]}"))"
declare -r ARCHIVES_DIR="${ROOT_DIR}/.neovim-cache/archives"
declare -r REPOS_DIR="${ROOT_DIR}/.neovim-cache/repos"
declare -r INSTALLATION_DIR="${ROOT_DIR}/neovim"

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

declare -r prebuilt_package_url="https://github.com/neovim/neovim/releases/download/${tag}/nvim-${platform}.tar.gz"
declare -r prebuilt_package_filename=$(basename "${prebuilt_package_url}")

declare -r repo_url="https://github.com/neovim/neovim"

function command_exists() {
  type "${1}" >/dev/null 2>&1
}

function is_darwin() {
  [[ "${RUNNER_OS}" = "macOS" ]]
}

function is_linux() {
  [[ "${RUNNER_OS}" = "Linux" ]]
}

function setup_apt_packages() {
  local apt_bin="apt"
  if command_exists apt-fast; then
    apt_bin="apt-fast"
  fi
  echo "Installing packages: $*"
  sudo $apt_bin install -qq --yes "$@"
}

function setup_brew_packages() {
  echo "Installing packages: $*"
  printf 'brew "%s"\n' $* |  brew bundle --no-lock --file=-
}

function get_latest_reposiotry() {
  mkdir -p "${REPOS_DIR}"

  local -r repo_uri="${1}"
  local -r repo_dir="${2}"

  echo "Repository URI: ${repo_uri}"
  if [[ ! -d "${repo_dir}" ]]; then
    echo "Cloning repository..."
    git clone --recursive "${repo_uri}" "${repo_dir}"
    pushd "${repo_dir}" >/dev/null
  else
    echo "Pulling latest commits..."
    pushd "${repo_dir}" >/dev/null
    git fetch --all --tags
    git submodule update --init
  fi

  popd >/dev/null
}

function setup_from_source() {
  get_latest_reposiotry "${repo_url}" "${REPOS_DIR}/neovim"
  pushd "${REPOS_DIR}/neovim" >/dev/null

  local ref="stable"
  if git tag --list | grep -q "${tag}"; then
    ref="${tag}"
  elif test "${tag}" = "nightly"; then
    ref="master"
  elif test "${tag}" = "source"; then
    ref="master"
  fi
  git checkout "${ref}"

  echo "Installing dependencies..."

  if is_darwin; then
    setup_brew_packages ninja libtool automake cmake pkg-config gettext curl
  fi

  if is_linux; then
    setup_apt_packages ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl
  fi

  echo "Running build..."
  make distclean
  make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="${INSTALLATION_DIR}" cmake

  echo "Installing..."
  make install

  echo "Setting PATH..."
  echo "${INSTALLATION_DIR}/bin" >> ${GITHUB_PATH}
}

function is_prebuilt_package_available() {
  local status_code="$(curl -sL --head --write-out "%{http_code}" --output /dev/null "${prebuilt_package_url}")"
  test "${status_code}" = "200"
}

function setup_prebuilt_package() {
  if is_prebuilt_package_available; then
    mkdir -p "${ARCHIVES_DIR}"

    echo "Downloading archive..."
    curl --progress-bar --continue-at - --output "${ARCHIVES_DIR}/${prebuilt_package_filename}" -L "${prebuilt_package_url}"

    echo "Extracting archive..."
    tar --strip-components=1 -xzf "${ARCHIVES_DIR}/${prebuilt_package_filename}" -C "${INSTALLATION_DIR}"

    echo "Setting PATH..."
    echo "${INSTALLATION_DIR}/bin" >> ${GITHUB_PATH}
  else
    echo "Prebuilt package for tag '${tag}' not available!"
    echo "Falling back to source compilation."
    echo
    setup_from_source
  fi
}

mkdir -p "${INSTALLATION_DIR}"

if test "${tag}" = "source"; then
  setup_from_source
else
  setup_prebuilt_package
fi
