#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
wrapper="$repo_dir/ffmpeg-smart.sh"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/ffadaptive-cli.XXXXXX")"
test_cleanup() { rm -rf -- "$test_dir"; }
trap test_cleanup EXIT

for removed in -hdr -10bit -deinterlace -maxbitrate; do
    set +e
    "$wrapper" --help "$removed" > "$test_dir/${removed#-}.log" 2>&1
    status=$?
    set -e
    [[ "$status" -eq 64 ]]
    grep -Fq "Unknown option: $removed" "$test_dir/${removed#-}.log"
done

"$wrapper" --help -sdr -deint -maxbr 2M > "$test_dir/canonical.log"
grep -Fq 'Usage: ffmpeg-smart.sh' "$test_dir/canonical.log"

for invalid in 'h264,' 'h264,,hevc' 'h264;touch_bad' 'h2 64' '' 'preferred,h264' 'h264,preferred' 'preferred,preferred'; do
    set +e
    "$wrapper" -i input.ts --copy-codecs "$invalid" > "$test_dir/copy-codecs.log" 2>&1
    status=$?
    set -e
    [[ "$status" -eq 64 ]]
    grep -Fq -- '--copy-codecs requires' "$test_dir/copy-codecs.log"
done
set +e
"$wrapper" -i input.ts --fallback-codec unsupported > "$test_dir/fallback.log" 2>&1
status=$?
set -e
[[ "$status" -eq 64 ]]
grep -Fq -- '--fallback-codec must be h264 or hevc' "$test_dir/fallback.log"

echo 'Canonical policy option and removed-alias tests passed'
