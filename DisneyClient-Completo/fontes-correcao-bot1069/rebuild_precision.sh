#!/usr/bin/env bash
# Usage: FFDEC_HOME=... RUFFLE_PACKAGE=... NODE_PATH=... bash rebuild_precision.sh input.swf output.swf
set -euo pipefail
: "${FFDEC_HOME:?Set FFDEC_HOME to the extracted FFDec 26.4.0 directory}"
: "${RUFFLE_PACKAGE:?Set RUFFLE_PACKAGE to the installed @ruffle-rs/ruffle 0.7.1 directory}"
if [ "$#" -ne 2 ]; then echo 'Usage: rebuild_precision.sh input.swf output.swf' >&2; exit 2; fi
source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf -- "$build_dir"' EXIT
ffdec_cp="$FFDEC_HOME/ffdec.jar:$FFDEC_HOME/lib/*"
java -jar "$FFDEC_HOME/ffdec.jar" -replace "$1" "$build_dir/updated.swf" disney.RoutePlayerFixed1069 "$source_dir/RoutePlayerFixed1069.as"
java -cp "$ffdec_cp" "$source_dir/VerifyPrecision.java" "$1" "$build_dir/updated.swf"
java -cp "$ffdec_cp" "$source_dir/BuildFixture.java" "$build_dir/updated.swf" "$source_dir/RoutePlayerTests.as" "$build_dir/test.swf"
cp "$source_dir/"{test.html,run_avm2_test.js,routes-fixture.json,route-2294519.json} "$build_dir/"
cp -R "$source_dir/fixtures" "$build_dir/fixtures"
mkdir "$build_dir/ruffle"
ln -s "$(realpath -- "$RUFFLE_PACKAGE")" "$build_dir/ruffle/package"
node "$build_dir/run_avm2_test.js"
cp -- "$build_dir/updated.swf" "$2"
