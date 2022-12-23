#!/bin/bash -e

pushd modules/csharp/examples/code_snippets
dotnet add package --prerelease couchbase.lite.enterprise
dotnet restore
dotnet build --no-restore -c Release