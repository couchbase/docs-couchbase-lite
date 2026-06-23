#!/bin/bash -e

if [[ "$#" -ne 1 ]]; then
    echo "This script requires a version argument"
    exit 1
fi

THIS_DIR=$( dirname -- $(realpath "$0") )
CBL_VERSION="$1"
pushd "$THIS_DIR/../modules/c/examples/code_snippets_cpp"

RESPONSE=$(curl -s "http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-c&version=${CBL_VERSION}")
CBL_IS_RELEASE=$(echo -n "$RESPONSE" | jq .IsRelease)
CBL_BUILD_NO=$(echo -n "$RESPONSE" | jq .BuildNumber)

if [ "${CBL_BUILD_NO}" == "" ] || [ "${CBL_BUILD_NO}" == "null" ]; then
    echo "No latest successful build found for CBL v${CBL_VERSION}"
    exit 3
fi

if [ "${CBL_IS_RELEASE}" == "true" ]; then
    PACKAGE_NAME="couchbase-lite-c-enterprise-${CBL_VERSION}-linux-x86_64.tar.gz"
    DOWNLOAD_URL="https://latestbuilds.service.couchbase.com/builds/releases/mobile/couchbase-lite-c/${CBL_VERSION}/${PACKAGE_NAME}"
else
    PACKAGE_NAME="couchbase-lite-c-enterprise-${CBL_VERSION}-${CBL_BUILD_NO}-linux-x86_64.tar.gz"
    DOWNLOAD_URL="https://latestbuilds.service.couchbase.com/builds/latestbuilds/couchbase-lite-c/${CBL_VERSION}/${CBL_BUILD_NO}/${PACKAGE_NAME}"
fi

rm -rf downloaded
mkdir -p downloaded

pushd downloaded
DOWNLOAD_DIR=$(pwd)
wget "${DOWNLOAD_URL}"
tar xf "${PACKAGE_NAME}"
rm "${PACKAGE_NAME}"
popd

mkdir -p build
pushd build
cmake -DCMAKE_PREFIX_PATH="$DOWNLOAD_DIR/libcblite-${CBL_VERSION}" ..
make -j12
