#!/bin/bash -e

cbl_version=$1

dir=$( dirname -- $(realpath "$0"); )

# Get latest good CBL iOS EE build for given version
CBL_URL="http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-ios&version=${cbl_version}"

# Grab the redirect url
CBL_SOURCE_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "${CBL_URL}")

cbl_build=$(curl -s "http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-ios&version=$cbl_version&ee=true" | jq .BuildNumber)

for PLATFORM in "objc" "swift"
do
    echo $PLATFORM
    pushd "${dir}/../modules/${PLATFORM}/examples"

    # In case script fails mid-way, cleanup on start
    if [ -d "downloaded" ]; then
        rm -rf "downloaded"
    fi
    mkdir -p downloaded

    pushd downloaded
    # Get CBL
    CBL_PACKAGE_NAME="couchbase-lite-${PLATFORM}_xc_enterprise_${cbl_version}-${cbl_build}.zip"
    wget "$CBL_SOURCE_URL$CBL_PACKAGE_NAME"
    unzip -o $CBL_PACKAGE_NAME -d "../Frameworks/"
    # Check if download was successful
    if [ $? -eq 0 ]; then
        echo "Package downloaded successfully."
    else
        echo "Failed to download the package."
    fi

    popd

    # Build snippets app
    TEST_SIMULATOR=$(xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | sed 's/Simulator//g' | awk '{$1=$1;print}')
    echo "TEST_SIMULATOR=${TEST_SIMULATOR}"
    xcodebuild build -project code_snippets.xcodeproj -scheme "code-snippets" -destination "platform=iOS Simulator,name=${TEST_SIMULATOR}"
    popd

done
