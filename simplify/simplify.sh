#!/bin/bash
set -euf -o pipefail
set -x

SCRIPT_DIR=$(realpath $(dirname $0))
echo $SCRIPT_DIR

cd $SCRIPT_DIR/../../docs-site

ln -f $SCRIPT_DIR/antora-assembler.yml .
ln -f $SCRIPT_DIR/mobile.yml .
ln -f $SCRIPT_DIR/attributes.pl .
ln -f $SCRIPT_DIR/rename.sh .

# npx antora mobile.yml

split -p :docname: build/assembler/couchbase-lite/current/android.adoc android.

./rename.sh android.*

perl -i.bak attributes.pl android-database.adoc

cp android-database.adoc $SCRIPT_DIR/../modules/android/pages/database.adoc
