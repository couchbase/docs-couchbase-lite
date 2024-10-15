#!/bin/bash
set -exu -o pipefail

SCRIPT_DIR=$(realpath $(dirname $0))
cd $SCRIPT_DIR/..
git checkout release/3.2 -- modules/android/pages/*.adoc
git checkout release/3.2 -- modules/c/pages/*.adoc
git checkout release/3.2 -- modules/csharp/pages/*.adoc
git checkout release/3.2 -- modules/java/pages/*.adoc
git checkout release/3.2 -- modules/objc/pages/*.adoc
git checkout release/3.2 -- modules/swift/pages/*.adoc

cd $SCRIPT_DIR/../../docs-site

ln -f $SCRIPT_DIR/antora-assembler.yml .
ln -f $SCRIPT_DIR/mobile.yml .
ln -f $SCRIPT_DIR/attributes.pl .
ln -f $SCRIPT_DIR/rename.sh .

## UNCOMMENT THIS to run Antora with the assembler feature 
npx antora mobile.yml

process() {
    WHAT=$1
    FROM=${2:-$WHAT}
    split -p :docname: \
        build/assembler/couchbase-lite/current/${FROM}.adoc \
        ${WHAT}.

    ./rename.sh ${WHAT}.*

    for ADOC in ${WHAT}-*.adoc; do
        perl -i attributes.pl $ADOC
        NEW=${ADOC#${WHAT}-}
        if [ "$NEW" != ".adoc" ]
        then
            cp $ADOC $SCRIPT_DIR/../modules/${WHAT}/pages/$NEW
        fi

    done
}

process android
process c
process csharp -net
process java
process javascript
process objc objective-c
process swift
