#!/bin/bash

for FILE in $@
do
    PREFIX=${FILE%.*}
    NEW=$(grep :docname: $FILE | cut -d' ' -f2)
    echo mv $FILE $PREFIX-$NEW.adoc
    mv $FILE $PREFIX-$NEW.adoc
done
