#!/bin/bash -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CBL_VERSION="$1"
VS_VERSION="$2"

ANDROID_DIR=$SCRIPT_DIR/../modules/android

if ! hash curl >/dev/null 2>&1; then
    echo "curl not found, aborting..."
    exit 1
fi

if hash jq 2>/dev/null; then
    JQ=jq
else
    echo "jq is not installed, downloading a local copy..."
    
    # Detect OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$OS" in
        linux)
            case "$ARCH" in
                x86_64|amd64)
                    JQ_BINARY="jq-linux-amd64"
                    ;;
                aarch64|arm64)
                    JQ_BINARY="jq-linux-arm64"
                    ;;
                *)
                    echo "Unsupported Linux architecture: $ARCH"
                    exit 1
                    ;;
            esac
            ;;
        darwin)
            case "$ARCH" in
                x86_64|amd64)
                    JQ_BINARY="jq-macos-amd64"
                    ;;
                arm64)
                    JQ_BINARY="jq-macos-arm64"
                    ;;
                *)
                    echo "Unsupported macOS architecture: $ARCH"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.8.1/${JQ_BINARY}"
    echo "Downloading jq for $OS/$ARCH: $JQ_URL"
    
    # Download jq using curl
    curl -L "$JQ_URL" -o /tmp/jq-local
    
    chmod +x /tmp/jq-local
    JQ=/tmp/jq-local
fi


CBL_URL="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-android&version=${CBL_VERSION}"
VS_URL="http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-android-vector-search&version=${VS_VERSION}"

CBL_RESPONSE=$(curl -s $CBL_URL)
CBL_IS_RELEASE=$(echo -n "$CBL_RESPONSE" | $JQ -r '.IsRelease')
CBL_BUILD=$(echo -n "$CBL_RESPONSE" | $JQ -r '.BuildNumber')

if [ "${CBL_BUILD}" == "" ] || [ "${CBL_BUILD}" == "null" ]; then
    echo "No latest successful build found for CBL v${CBL_VERSION}"
    exit 3
fi

VS_RESPONSE=$(curl -s $VS_URL)
VS_IS_RELEASE=$(echo -n "$VS_RESPONSE" | $JQ -r '.IsRelease')
VS_BUILD=$(echo -n "$VS_RESPONSE" | $JQ -r '.BuildNumber')

if [ "${VS_BUILD}" == "" ] || [ "${VS_BUILD}" == "null" ]; then
    echo "No latest successful build found for VS v${VS_VERSION}"
    exit 3
fi

if [ "${CBL_IS_RELEASE}" == "true" ]; then
    CBL_VERSION_ARG="${CBL_VERSION}"
else
    CBL_VERSION_ARG="${CBL_VERSION}-${CBL_BUILD}"
fi

if [ "${VS_IS_RELEASE}" == "true" ]; then
    VS_VERSION_ARG="${VS_VERSION}"
else
    VS_VERSION_ARG="${VS_VERSION}-${VS_BUILD}"
fi

pushd $ANDROID_DIR/examples/
./gradlew assembleDebug -PcblVersion=${CBL_VERSION_ARG} -PextVersion=${VS_VERSION_ARG}