#!/bin/bash -e

CBL_VERSION=$1
VS_VERSION=$2

if [ -z "${CBL_VERSION}" ] || [ -z "${VS_VERSION}" ]; then
    echo "Usage: $0 <CBL_VERSION> <VS_VERSION>"
    exit 1
fi

dir=$( dirname -- $(realpath "$0") )

CBL="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-ios&version=${CBL_VERSION}"
RESPONSE=$(curl -s $CBL)
CBL_IS_RELEASE=$(echo -n "$RESPONSE" | jq .IsRelease)
CBL_BUILD_NO=$(echo -n "$RESPONSE" | jq .BuildNumber)

if [ "${CBL_BUILD_NO}" == "" ] || [ "${CBL_BUILD_NO}" == "null" ]
then
    echo "No latest successful build found for CBL v${CBL_VERSION}"
    exit 3
fi

VS="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-ios-vector-search&version=${VS_VERSION}&ee=true"
RESPONSE=$(curl -s $VS)
VS_IS_RELEASE=$(echo -n "$RESPONSE" | jq .IsRelease)
VS_BUILD_NO=$(echo -n "$RESPONSE" | jq .BuildNumber)

if [ "${VS_BUILD_NO}" == "" ] || [ "${VS_BUILD_NO}" == "null" ]
then
    echo "No latest successful build found for VS v${VS_VERSION}"
    exit 3
fi

# Download VS extension once (platform-independent)
if [ "${VS_IS_RELEASE}" == "true" ]; then
    VS_PACKAGE_NAME="couchbase-lite-vector-search-${VS_VERSION}-apple.zip"
    VS_URL="https://latestbuilds.service.couchbase.com/builds/releases/mobile/couchbase-lite-vector-search/${VS_VERSION}/${VS_PACKAGE_NAME}"
else
    VS_PACKAGE_NAME="couchbase-lite-vector-search-${VS_VERSION}-${VS_BUILD_NO}-apple.zip"
    VS_URL="https://latestbuilds.service.couchbase.com/builds/latestbuilds/couchbase-lite-vector-search/${VS_VERSION}/${VS_BUILD_NO}/${VS_PACKAGE_NAME}"
fi

VS_DOWNLOAD_DIR="${dir}/../vs_downloaded"
rm -rf "${VS_DOWNLOAD_DIR}"
mkdir -p "${VS_DOWNLOAD_DIR}"
wget -P "${VS_DOWNLOAD_DIR}" "${VS_URL}"

for PLATFORM in "objc" "swift"
do
    echo $PLATFORM
    pushd "${dir}/../modules/${PLATFORM}/examples"

    # In case script fails mid-way, cleanup on start
    rm -rf "downloaded"
    mkdir -p downloaded

    pushd downloaded

    # Get CBL
    if [ "${CBL_IS_RELEASE}" == "true" ]; then
        CBL_PACKAGE_NAME="couchbase-lite-${PLATFORM}_xc_enterprise_${CBL_VERSION}.zip"
        CBL_URL="https://latestbuilds.service.couchbase.com/builds/releases/mobile/couchbase-lite-ios/${CBL_VERSION}/${CBL_PACKAGE_NAME}"
    else
        CBL_PACKAGE_NAME="couchbase-lite-${PLATFORM}_xc_enterprise_${CBL_VERSION}-${CBL_BUILD_NO}.zip"
        CBL_URL="https://latestbuilds.service.couchbase.com/builds/latestbuilds/couchbase-lite-ios/${CBL_VERSION}/${CBL_BUILD_NO}/${CBL_PACKAGE_NAME}"
    fi

    wget "${CBL_URL}"
    unzip -o "${CBL_PACKAGE_NAME}" -d "../Frameworks/"

    # Get VS extension
    unzip -o "${VS_DOWNLOAD_DIR}/${VS_PACKAGE_NAME}" -d "../Frameworks/"

    popd

    # Build snippets app
    TEST_SIMULATOR=$(xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | sed 's/Simulator//g' | awk '{$1=$1;print}')
    echo "TEST_SIMULATOR=${TEST_SIMULATOR}"
    xcodebuild build -project code_snippets.xcodeproj -scheme "code-snippets" -destination "platform=iOS Simulator,name=${TEST_SIMULATOR}"
    popd

done

rm -rf "${VS_DOWNLOAD_DIR}"
