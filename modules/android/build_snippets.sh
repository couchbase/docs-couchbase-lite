#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ANDROID_DIR=$SCRIPT_DIR
JAVA_DIR=$SCRIPT_DIR/../java

# Kotlin code is in the examples subdirectory
cat $ANDROID_DIR/examples/kotlin_snippets/app/src/main/kotlin/com/couchbase/codesnippets/* > snippet_collection.kt

# Android specific java code in in the examples subdirectory
cat $ANDROID_DIR/examples/java_snippets/app/src/main/java/com/couchbase/codesnippets/* > snippet_collection.java
# Most java code is generic and is over in the java/examples directory
cat $JAVA_DIR/examples/snippets/common/main/java/com/couchbase/codesnippets/* >> snippet_collection.java

