#!/usr/bin/env bash

set -ex

# Read parameters
TAG=$1
if [ -z $TAG ]; then
    echo '"TAG" must be specified'
    exit 1
fi

# Paths
CWD=$(pwd)
BUILD_PATH="${CWD}/build/$TAG"
VAULT_PATH="${CWD}/vault"
WEBSITE_PATH="${VAULT_PATH}/website"

# Clean build
rm -rf "${BUILD_PATH}"
mkdir -p "${BUILD_PATH}"

# Checkout and clean
git clone "https://github.com/hashicorp/vault.git" || true
cd "${VAULT_PATH}"
git fetch --all --prune
git checkout -- .
git checkout "v${TAG}"

# Install gems
cd "${WEBSITE_PATH}"
bundle install

rm Rakefile || true
# cp "${CWD}/Rakefile" .
ln -s "${CWD}/Rakefile" || true

# Build
rake

mv Vault.tgz "${BUILD_PATH}"