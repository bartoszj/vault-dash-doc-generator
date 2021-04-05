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
if [[ ${OSTYPE} == "linux-gnu"* ]] && [[ -d ${WEBSITE_PATH} ]]; then
  sudo chown -R $(id -u):$(id -g) ${WEBSITE_PATH}
fi

# Checkout and clean
git clone "https://github.com/hashicorp/vault.git" || true
cd "${VAULT_PATH}"
git fetch --all --prune
git clean -fdx
git checkout -- .
git checkout "v${TAG}"

# Install gems
cd "${WEBSITE_PATH}"

rm Rakefile || true
# cp "${CWD}/Rakefile" .
ln -s "${CWD}/Rakefile" || true

# Build
ulimit -n 16000 || true
if [[ ${OSTYPE} == "linux-gnu"* ]]; then
  sed -i'' 's|npm run static$|bash -c \"npm install; npm run static\"|g' Makefile
  sed -i'' 's|--rm|--rm --env NODE_OPTIONS=--max-old-space-size=4096|g' Makefile
  sed -i'' 's|unstable_getStaticProps|getStaticProps|g' pages/downloads/index.jsx # Can be removed from version 1.5.0
  sed -i'' 's| && cp _redirects out/.||g' package.json
else
  sed -i '' 's|npm run static$|bash -c \"npm install; npm run static\"|g' Makefile
  sed -i '' 's|--rm|--rm --env NODE_OPTIONS=--max-old-space-size=4096|g' Makefile
  sed -i '' 's|unstable_getStaticProps|getStaticProps|g' pages/downloads/index.jsx # Can be removed from version 1.5.0
  sed -i '' 's| && cp _redirects out/.||g' package.json
fi

# Can be removed since version 1.7.0?
if [[ -e pages/api-docs/system/index.mdx && -e content/api-docs/system/internal-ui-feature.mdx ]]; then
  cp content/api-docs/system/internal-ui-feature.mdx pages/api-docs/system/
fi

rake

mv Vault.tgz "${BUILD_PATH}"
