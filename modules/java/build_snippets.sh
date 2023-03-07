#!/bin/sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cat $SCRIPT_DIR/examples/snippets/src/main/java/com/couchbase/codesnippets/* > snippet_collection.java 2> /dev/null
cat $SCRIPT_DIR/examples/snippets/common/main/java/com/couchbase/codesnippets/* >> snippet_collection.java 2> /dev/null

