#!/bin/bash -e

CBL_VERSION=$1
VS_VERSION=$2

dir=$( dirname -- $(realpath "$0"); )

# Get latest good CBL iOS EE build for given version
CBL_URL="http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-ios&version=${cbl_version}"

# Grab the redirect url
CBL_SOURCE_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "${CBL_URL}")

CBL="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-ios&version=${CBL_VERSION}"
RESPONSE=$(curl -s $CBL)
CBL_IS_RELEASE=$(echo -n $RESPONSE | jq .IsRelease)
CBL_BUILD_NO=$(echo -n $RESPONSE | jq .BuildNumber)

if [ "${CBL_BUILD_NO}" == "" ]
then
    echo "No latest successful build found for CBL v${CBL_VERSION}"
    exit 3
fi

VS="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-ios-vector-search&version=${VS_VERSION}&ee=true"
RESPONSE=$(curl -s $VS)
VS_BUILD_NO=$(echo -n $RESPONSE | jq .BuildNumber)

if [ "${VS_BUILD_NO}" == "" ]
then
    echo "No latest successful build found for VS v${VS_VERSION}"
    exit 3
fi

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
    CBL_SOURCE_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-ios&version=${CBL_VERSION}")

    if [ $CBL_IS_RELEASE == true ]; then
        CBL_PACKAGE_NAME="couchbase-lite-${PLATFORM}_xc_enterprise_${CBL_VERSION}.zip"
    else
        CBL_PACKAGE_NAME="couchbase-lite-${PLATFORM}_xc_enterprise_${CBL_VERSION}-${CBL_BUILD_NO}.zip"
    fi

    wget "$CBL_SOURCE_URL$CBL_PACKAGE_NAME"
    unzip -o $CBL_PACKAGE_NAME -d "../Frameworks/"

    # Get VS extension
    VS_SOURCE_URL=$(curl -s -L -o /dev/null -w '%{url_effective}' "http://proget.build.couchbase.com:8080/api/open_latestbuilds?product=couchbase-lite-ios-vector-search&version=${VS_VERSION}")
    echo $VS_SOURCE_URL
    VS_PACKAGE_NAME="couchbase-lite-vector-search-${VS_VERSION}-${VS_BUILD_NO}-apple.zip"
    wget "$VS_SOURCE_URL$VS_PACKAGE_NAME"
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
    echo "TEST_SIMULATOR=${TEST_SIMULATOR}"
    xcodebuild build -project code_snippets.xcodeproj -scheme "code-snippets" -destination "platform=iOS Simulator,name=${TEST_SIMULATOR}"
    popd

done
