#!/bin/bash -e

if [[ "$#" -ne 1 ]]; then
    echo "This script requires a version argument"
fi

THIS_DIR=$( dirname -- $(realpath "$0"); )
VERSION="$1"

# Get latest good built
URL="http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-ios&version=${VERSION}"

# Grab the redirect url
SOURCE_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "${URL}")

# Extract version and build number
BUILD_NUMBER=$(basename "${SOURCE_URL}")

# http://latestbuilds.service.couchbase.com/builds/latestbuilds/couchbase-lite-ios/3.2.0/97/couchbase-lite-swift_xc_enterprise_3.2.0-97.zip
# http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-vector-search
# Construct version with build number
BUILD="${VERSION}-${BUILD_NUMBER}"

PLATFORMS=("swift", "objc")

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
    # Get package
    PACKAGE_NAME="couchbase-lite-${PLATFORM}_xc_enterprise_${BUILD}.zip"
    wget "$SOURCE_URL$PACKAGE_NAME"

    # Check if download was successful
    if [ $? -eq 0 ]; then
        echo "Package downloaded successfully."
    else
        echo "Failed to download the package."
    fi

    # Move library into Frameworks
    unzip $PACKAGE_NAME -d "../Frameworks/"
    popd
    
    popd
done


# # TEST_SIMULATOR=$(xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | sed 's/Simulator//g' | awk '{$1=$1;print}')
# # xcodebuild build -project code_snippets.xcodeproj -scheme "code-snippets" -destination "platform=iOS Simulator,name=${TEST_SIMULATOR}"