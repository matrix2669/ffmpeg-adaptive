#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/ffsmart-integrity.XXXXXX")"
test_cleanup() { rm -rf -- "$test_dir"; }
trap test_cleanup EXIT

source "$repo_dir/lib/ffsmart-common.sh"
source "$repo_dir/lib/ffsmart-cache.sh"
source "$repo_dir/lib/ffsmart-hardware.sh"

FFSMART_STATE_DIR="$test_dir/state"
mkdir -p -- "$FFSMART_STATE_DIR"
FFSMART_CACHE_FILE="$FFSMART_STATE_DIR/.capabilities.cache"
FFSMART_LOCK_FILE="$FFSMART_STATE_DIR/.benchmark.lock"
FFSMART_CACHE_SCHEMA=2
FFSMART_H264_SAMPLE="$test_dir/h264.mkv"
FFSMART_HEVC10_SAMPLE="$test_dir/hevc10.mkv"
printf 'sample\n' > "$FFSMART_H264_SAMPLE"
printf 'sample\n' > "$FFSMART_HEVC10_SAMPLE"

ffsmart_lock_acquire() { :; }
ffsmart_ensure_benchmark_samples() { :; }
ffsmart_encoder_available() { return 0; }
ffsmart_current_fingerprint() { printf 'test-fingerprint'; }
ffsmart_build_benchmark_command() { FFSMART_BENCH_CMD=(bash -c 'printf "frame=1 speed=2x\\n" >&2'); }
ffsmart_cache_write() { printf 'new-cache\n' > "$FFSMART_CACHE_FILE"; }

# A diagnostic path failure must cross the candidate boundary in the parent
# shell; command substitution in the old caller hid this flag.
ffsmart_refresh_hardware_inventory() {
    FFSMART_RENDER_NODES=(/dev/dri/renderD128)
    ffsmart_device_set signature /dev/dri/renderD128 0x8086:test
}
ffsmart_benchmark_log_path() { printf '%s/missing/worker.log' "$FFSMART_STATE_DIR"; }
FFSMART_RENDER_NODES=()
FFSMART_BENCHMARK_LOG_FAILURE=false
if ffsmart_rebuild_cache true; then
    echo 'diagnostic path failure unexpectedly succeeded' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]
[[ "$FFSMART_BENCHMARK_LOG_FAILURE" == true ]]
[[ ! -e "$FFSMART_STATE_DIR/benchmark-latest.log" ]]

FFSMART_BENCHMARK_LOG_FAILURE=false
if ffsmart_probe_10bit /dev/dri/renderD128 vaapi decode; then
    echo '10-bit diagnostic path failure unexpectedly succeeded' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]
[[ "$FFSMART_BENCHMARK_LOG_FAILURE" == true ]]

# A cache-write failure must retain an existing usable cache and prior summary.
printf 'old-cache\n' > "$FFSMART_CACHE_FILE"
printf 'old-summary\n' > "$FFSMART_STATE_DIR/benchmark-latest.log"
ffsmart_refresh_hardware_inventory() { FFSMART_RENDER_NODES=( - ); }
ffsmart_cache_write() { return 73; }
ffsmart_benchmark_log_path() { printf '%s' "$FFSMART_BENCHMARK_RUN_DIR/worker.log"; }
if ffsmart_rebuild_cache true; then
    echo 'cache write failure unexpectedly succeeded' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]
[[ "$(<"$FFSMART_CACHE_FILE")" == old-cache ]]
[[ "$(<"$FFSMART_STATE_DIR/benchmark-latest.log")" == old-summary ]]

# Every input read is checked before publication; a directory masquerading as
# a worker log must not replace the prior summary or purge evidence.
FFSMART_BENCHMARK_RUN_DIR="$FFSMART_STATE_DIR/.benchmark-run.read"
mkdir -p -- "$FFSMART_BENCHMARK_RUN_DIR/a.log"
printf 'new-evidence\n' > "$FFSMART_BENCHMARK_RUN_DIR/z.log"
if ffsmart_publish_benchmark_log; then
    echo 'unreadable worker log unexpectedly published' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]
[[ "$(<"$FFSMART_STATE_DIR/benchmark-latest.log")" == old-summary ]]
[[ -d "$FFSMART_BENCHMARK_RUN_DIR" ]]

# An existing directory at the publication target must never become the move
# destination (mv would otherwise place the summary inside it).
rm -rf -- "$FFSMART_BENCHMARK_RUN_DIR"
FFSMART_BENCHMARK_RUN_DIR="$FFSMART_STATE_DIR/.benchmark-run.write"
mkdir -- "$FFSMART_BENCHMARK_RUN_DIR"
printf 'new-evidence\n' > "$FFSMART_BENCHMARK_RUN_DIR/z.log"
rm -f -- "$FFSMART_STATE_DIR/benchmark-latest.log"
mkdir -- "$FFSMART_STATE_DIR/benchmark-latest.log"
if ffsmart_publish_benchmark_log; then
    echo 'directory publication target unexpectedly accepted' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]
[[ -d "$FFSMART_STATE_DIR/benchmark-latest.log" ]]

# Successful publication is atomic with respect to retention: repeated phase
# names remain distinct, older root logs and failed-run directories are purged
# only after the new summary is in place, and exactly one latest summary stays.
rm -rf -- "$FFSMART_STATE_DIR/benchmark-latest.log"
FFSMART_BENCHMARK_RUN_DIR="$FFSMART_STATE_DIR/.benchmark-run.success"
mkdir -- "$FFSMART_BENCHMARK_RUN_DIR"
printf 'first\n' > "$FFSMART_BENCHMARK_RUN_DIR/candidate-repeat-1.log"
printf 'second\n' > "$FFSMART_BENCHMARK_RUN_DIR/candidate-repeat-2.log"
printf 'old-root\n' > "$FFSMART_STATE_DIR/candidate-old.log"
printf 'operator-results\n' > "$FFSMART_STATE_DIR/benchmark-accel-results.tsv"
mkdir -- "$FFSMART_STATE_DIR/.benchmark-run.failed"
printf 'old-failed\n' > "$FFSMART_STATE_DIR/.benchmark-run.failed/old.log"
ffsmart_publish_benchmark_log
[[ -f "$FFSMART_STATE_DIR/benchmark-latest.log" ]]
[[ "$(grep -c '^===== candidate-repeat-' "$FFSMART_STATE_DIR/benchmark-latest.log")" == 2 ]]
[[ ! -e "$FFSMART_STATE_DIR/candidate-old.log" ]]
[[ "$(<"$FFSMART_STATE_DIR/benchmark-accel-results.tsv")" == operator-results ]]
[[ ! -e "$FFSMART_STATE_DIR/.benchmark-run.failed" ]]
[[ ! -e "$FFSMART_STATE_DIR/.benchmark-run.success" ]]

# Dangling symlinks are rejected before redirection; cleanup cannot escape the
# state directory through a symlink or a nested look-alike run directory.
ln -s "$FFSMART_STATE_DIR/outside-target" "$FFSMART_STATE_DIR/dangling.log"
if ffsmart_prepare_benchmark_log "$FFSMART_STATE_DIR/dangling.log"; then
    echo 'dangling diagnostic symlink unexpectedly accepted' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]

# A target can become unwritable after pre-creation. The checked FIFO writer
# must report that persistence failure even if FFmpeg itself exits cleanly.
FFSMART_BENCHMARK_RUN_DIR="$FFSMART_STATE_DIR/.benchmark-run.io"
mkdir -- "$FFSMART_BENCHMARK_RUN_DIR"
postcreate_log="$FFSMART_BENCHMARK_RUN_DIR/postcreate.log"
: > "$postcreate_log"
FFSMART_BENCH_CMD=(sh -c 'printf "diagnostic\\n" >&2')
rm -f -- "$postcreate_log"
mkdir -- "$postcreate_log"
if ffsmart_run_benchmark_command "$postcreate_log"; then
    echo 'post-create diagnostic write failure unexpectedly succeeded' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]

# A writer can consume the full diagnostic stream and still fail to persist it
# after the target was created. The failure must cross a complete candidate and
# rebuild boundary while retaining the prior cache and summary.
FFSMART_BENCHMARK_RUN_DIR="$FFSMART_STATE_DIR/.benchmark-run.writer"
mkdir -- "$FFSMART_BENCHMARK_RUN_DIR"
printf 'old-cache-writer\n' > "$FFSMART_CACHE_FILE"
printf 'old-summary-writer\n' > "$FFSMART_STATE_DIR/benchmark-latest.log"
ffsmart_benchmark_log_path() { printf '%s/writer.log' "$FFSMART_BENCHMARK_RUN_DIR"; }
source "$repo_dir/lib/ffsmart-cache.sh"
ffsmart_refresh_hardware_inventory() {
    FFSMART_RENDER_NODES=(/dev/dri/renderD128)
    ffsmart_device_set signature /dev/dri/renderD128 0x8086:test
}
writer_bin="$test_dir/writer-bin"
mkdir -- "$writer_bin"
real_cat="$(command -v cat)"
printf '#!/bin/sh\n"%s" "$@" > /dev/null\nexit 1\n' "$real_cat" > "$writer_bin/cat"
chmod +x "$writer_bin/cat"
old_path="$PATH"
PATH="$writer_bin:$PATH"
FFSMART_BENCH_CMD=(sh -c 'printf "ordinary diagnostic\\n" >&2; exit 0')
FFSMART_BENCHMARK_LOG_FAILURE=false
if ffsmart_rebuild_cache true; then
    echo 'mid-stream diagnostic writer failure unexpectedly succeeded' >&2
    exit 1
else
    status=$?
fi
PATH="$old_path"
[[ "$status" == 73 ]]
[[ "$FFSMART_BENCHMARK_LOG_FAILURE" == true ]]
[[ "$(<"$FFSMART_CACHE_FILE")" == old-cache-writer ]]
[[ "$(<"$FFSMART_STATE_DIR/benchmark-latest.log")" == old-summary-writer ]]

# A normal FFmpeg rejection remains status 1 rather than the diagnostic I/O
# status, preserving unsupported-codec/path semantics.
FFSMART_BENCHMARK_RUN_DIR="$FFSMART_STATE_DIR/.benchmark-run.ordinary"
mkdir -- "$FFSMART_BENCHMARK_RUN_DIR"
ffsmart_benchmark_log_path() { printf '%s/ordinary.log' "$FFSMART_BENCHMARK_RUN_DIR"; }
ffsmart_build_benchmark_command() { FFSMART_BENCH_CMD=(sh -c 'exit 1'); }
FFSMART_BENCHMARK_LOG_FAILURE=false
if ffsmart_benchmark_candidate /dev/dri/renderD128 vaapi h264 0 1; then
    echo 'ordinary benchmark rejection unexpectedly succeeded' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 1 ]]
[[ "$FFSMART_BENCHMARK_LOG_FAILURE" == false ]]

# The operator benchmark entry point has no rebuild run directory; its result
# capture is allowed directly under the state directory while worker logs stay
# in their generated unique files.
FFSMART_BENCHMARK_RUN_DIR=""
ffsmart_benchmark_candidate() { FFSMART_BENCHMARK_SPEED=3.5; printf '3.5'; }
ffsmart_run_benchmark_candidate /dev/dri/renderD128 vaapi h264 0 1
[[ "$FFSMART_BENCHMARK_SPEED" == 3.5 ]]

# A diagnostic failure while starting a concurrent capacity level must stop
# workers already launched for that level and never leave them orphaned.
rm -rf -- "$FFSMART_STATE_DIR/benchmark-latest.log"
FFSMART_BENCHMARK_RUN_DIR="$FFSMART_STATE_DIR/.benchmark-run.capacity"
mkdir -- "$FFSMART_BENCHMARK_RUN_DIR"
capacity_pid_file="$test_dir/capacity.pid"
ffsmart_build_benchmark_command() {
    FFSMART_BENCH_CMD=(sh -c "trap '' TERM; echo \$\$ > '$capacity_pid_file'; while :; do :; done")
}
capacity_prepare_count=0
ffsmart_prepare_benchmark_log() {
    capacity_prepare_count=$((capacity_prepare_count + 1))
    if (( capacity_prepare_count == 2 )); then
        sleep 0.2
        FFSMART_BENCHMARK_LOG_FAILURE=true
        return 73
    fi
    : > "$1"
}
if ffsmart_capacity_level_stable /dev/dri/renderD128 vaapi h264 0 2 30; then
    echo 'early capacity diagnostic failure unexpectedly succeeded' >&2
    exit 1
else
    status=$?
fi
[[ "$status" == 73 ]]
for wait_index in 1 2 3 4 5 6 7 8 9 10; do
    [[ -s "$capacity_pid_file" ]] && break
    sleep 0.1
done
[[ -s "$capacity_pid_file" ]]
capacity_pid="$(<"$capacity_pid_file")"
! kill -0 "$capacity_pid" 2>/dev/null

echo 'Benchmark diagnostic, cache transaction, and publication boundary tests passed'
