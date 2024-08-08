#!/bin/bash -e

cbl_version=${1:-3.1.0}

cbl_build=$(curl -s "http://proget.build.couchbase.com:8080/api/get_version?product=couchbase-lite-net&version=$cbl_version&ee=true" | jq .BuildNumber)

pushd modules/csharp/examples/code_snippets
dotnet add package couchbase.lite.enterprise -v $cbl_version-b$(printf "%04d" $cbl_build)
dotnet restore
dotnet build --no-restore -c Release