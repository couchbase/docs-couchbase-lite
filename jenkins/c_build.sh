#!/bin/bash -e

if [[ "$#" -ne 1 ]]; then
    echo "This script requires a version argument"
fi

THIS_DIR=$( dirname -- $(realpath "$0"); )
version="$1"
pushd "$THIS_DIR/../modules/c/examples/code_snippets"

build_num=$(curl -s http://dbapi.build.couchbase.com:8000/v1/products/couchbase-lite-c/releases/$version/versions/$version/builds?filter=last_complete | jq .build_num | bc)
mkdir -p downloaded

pushd downloaded
DOWNLOAD_DIR=$(pwd)
wget http://latestbuilds.service.couchbase.com/builds/latestbuilds/couchbase-lite-c/$version/$build_num/couchbase-lite-c-enterprise-$version-$build_num-ubuntu20.04-x86_64.tar.gz
tar xf couchbase-lite-c-enterprise-$version-$build_num-ubuntu20.04-x86_64.tar.gz
rm couchbase-lite-c-enterprise-$version-$build_num-ubuntu20.04-x86_64.tar.gz
popd

mkdir -p build
pushd build
cmake -DCMAKE_PREFIX_PATH="$DOWNLOAD_DIR/libcblite-$version" ..
make -j12