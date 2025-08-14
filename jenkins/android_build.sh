#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CBL_VERSION="$1"
VS_VERSION="$2"

ANDROID_DIR=$SCRIPT_DIR/../modules/android

CBL_URL="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-android&version=${CBL_VERSION}"
VS_URL="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-android-vector-search&version=${VS_VERSION}"

CBL_BUILD=$(curl -s $CBL_URL | jq -r '.BuildNumber')
VS_BUILD=$(curl -s $VS_URL | jq -r '.BuildNumber')

pushd $ANDROID_DIR/examples/
./gradlew assembleDebug -PcblVersion=$CBL_VERSION-$CBL_BUILD -PextVersion=$VS_VERSION-$VS_BUILD