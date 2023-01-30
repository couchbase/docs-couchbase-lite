#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ANDROID_DIR=$SCRIPT_DIR
JAVA_DIR=$SCRIPT_DIR/../java

cat $JAVA_DIR/examples/snippets/src/main/java/com/couchbase/codesnippets/* > snippet_collection.java
cat $ANDROID_DIR/examples/snippets/app/src/main/kotlin/com/couchbase/codesnippets/* > snippet_collection.kt

