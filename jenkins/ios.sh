#!/bin/bash -e

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 <CBL_VERSION> <VS_VERSION>"
    exit 1
fi

THIS_DIR=$( dirname -- $(realpath "$0"); )
CBL_VERSION="$1"
VS_VERSION="$2"

# Get latest good CBL iOS EE build
CBL_URL="http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-ios&version=${CBL_VERSION}"

# Grab the redirect url
CBL_SOURCE_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "${CBL_URL}")

# Extract version and build number
CBL_BUILD_NUMBER=$(basename "${CBL_SOURCE_URL}")

# Construct version with build number
CBL_BUILD="${CBL_VERSION}-${CBL_BUILD_NUMBER}"

# Get latest good VS extension build
VS_URL="http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-ios-vector-search&version=${VS_VERSION}"

# Grab the redirect url - workaround until url is fixed
VS_SOURCE_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "${VS_URL}" | sed 's/couchbase-lite-ios-vector-search/couchbase-lite-vector-search/')

VS_BUILD_NUMBER=$(basename "${VS_SOURCE_URL}")
VS_BUILD="${VS_VERSION}-${VS_BUILD_NUMBER}"

for PLATFORM in "swift" "objc"
do
    echo $PLATFORM
    pushd "${THIS_DIR}/../modules/${PLATFORM}/examples"

    # In case script fails mid-way, cleanup on start
    if [ -d "downloaded" ]; then
        rm -rf "downloaded"
    fi
    mkdir -p downloaded

    pushd downloaded
    # Get CBL
    CBL_PACKAGE_NAME="couchbase-lite-${PLATFORM}_xc_enterprise_${CBL_BUILD}.zip"
    wget "$CBL_SOURCE_URL$CBL_PACKAGE_NAME"
    unzip -o $CBL_PACKAGE_NAME -d "../Frameworks/"
    # Get VS extension
    VS_PACKAGE_NAME="couchbase-lite-vector-search-${VS_BUILD}-apple.zip"
    wget "$VS_SOURCE_URL/$VS_PACKAGE_NAME"
    unzip -o $VS_PACKAGE_NAME -d "../Frameworks/"
    # Check if download was successful
    if [ $? -eq 0 ]; then
        echo "Package downloaded successfully."
    else
        echo "Failed to download the package."
    fi

    popd

    # Build snippets app
    TEST_SIMULATOR=$(xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | sed 's/Simulator//g' | awk '{$1=$1;print}')
    xcodebuild build -project code_snippets.xcodeproj -scheme "code-snippets" -destination "platform=iOS Simulator,name=${TEST_SIMULATOR}"
    popd

done
