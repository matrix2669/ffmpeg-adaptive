#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/ffsmart-hardware.XXXXXX")"
test_cleanup() { rm -rf -- "$test_dir"; }
trap test_cleanup EXIT

source "$repo_dir/lib/ffsmart-common.sh"
source "$repo_dir/lib/ffsmart-cache.sh"
source "$repo_dir/lib/ffsmart-hardware.sh"
source "$repo_dir/lib/ffsmart-policy.sh"

FFSMART_H264_SAMPLE="$test_dir/h264.mkv"
FFSMART_HEVC10_SAMPLE="$test_dir/hevc10.mkv"
printf 'h264\n' > "$FFSMART_H264_SAMPLE"
printf 'hevc10\n' > "$FFSMART_HEVC10_SAMPLE"

ffsmart_build_benchmark_command /dev/dri/renderD128 vaapi h264 1 5
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- "$FFSMART_HEVC10_SAMPLE"
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- 'vaapi=ffsmart:/dev/dri/renderD128'
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- '-hwaccel'
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- 'vaapi'
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- '-hwaccel_output_format'
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- 'scale_vaapi=format=nv12'
! printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fq -- 'hwupload'

ffsmart_build_benchmark_command /dev/dri/renderD128 qsv hevc 1 5
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- "$FFSMART_HEVC10_SAMPLE"
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- 'qsv=ffsmart:hw,child_device=/dev/dri/renderD128'
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- '-hwaccel'
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- 'qsv'
printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fxq -- 'vpp_qsv=format=p010'
! printf '%s\n' "${FFSMART_BENCH_CMD[@]}" | grep -Fq -- 'hwupload'

ffsmart_cache_reset
FFSMART_CACHE_PRIMARY_DEVICE=/dev/dri/renderD128
FFSMART_CACHE_SECONDARY_DEVICE=/dev/dri/renderD129
ffsmart_device_set accel /dev/dri/renderD128 vaapi
ffsmart_device_set codec /dev/dri/renderD128 hevc
ffsmart_device_set low_power /dev/dri/renderD128 1
ffsmart_device_set encode10 /dev/dri/renderD128 true
ffsmart_device_set capacity /dev/dri/renderD128 12
ffsmart_device_set accel /dev/dri/renderD129 vaapi
ffsmart_device_set codec /dev/dri/renderD129 h264
ffsmart_device_set low_power /dev/dri/renderD129 0
ffsmart_device_set encode10 /dev/dri/renderD129 false
ffsmart_device_set capacity /dev/dri/renderD129 14
ffsmart_select_device vaapi h264
[[ "$FFSMART_SELECTED_DEVICE" == /dev/dri/renderD129 ]]

FFSMART_CACHE_PRIMARY_DEVICE=/dev/dri/renderD128
FFSMART_CACHE_SECONDARY_DEVICE=/dev/dri/renderD129
ffsmart_device_set codec /dev/dri/renderD128 h264
FFSMART_SELECTED_ACCEL=vaapi
FFSMART_TARGET_CODEC=h264
ffsmart_select_device vaapi h264
[[ "$FFSMART_SELECTED_DEVICE" == /dev/dri/renderD128 ]]
ffsmart_apply_selected_device_policy
[[ "$FFSMART_SELECTED_LOW_POWER" == 1 ]]
[[ "$FFSMART_SELECTED_10BIT_ENCODE" == true ]]

FFSMART_TARGET_CODEC=hevc
ffsmart_select_device vaapi hevc
[[ "$FFSMART_SELECTED_DEVICE" == /dev/dri/renderD128 ]]
ffsmart_apply_selected_device_policy
[[ "$FFSMART_SELECTED_LOW_POWER" == 0 ]]
[[ "$FFSMART_SELECTED_10BIT_ENCODE" == false ]]

FFSMART_SELECTED_ACCEL=vaapi
FFSMART_SELECTED_DEVICE=/dev/dri/renderD129
FFSMART_TARGET_CODEC=h264
FFSMART_VIDEO_PIX_FMT=yuv420p10le
FFSMART_VIDEO_HEIGHT=1080
FFSMART_VIDEO_WIDTH=1920
FFSMART_OUTPUT_HEIGHT=720
FFSMART_OUTPUT_WIDTH=1280
FFSMART_DEINTERLACE=false
FFSMART_FORCE_SDR=false
FFSMART_SELECTED_LOW_POWER=0
FFSMART_SELECTED_10BIT_ENCODE=true
FFSMART_VIDEO_COLOR_TRANSFER=smpte2084
FFSMART_VIDEO_COLOR_PRIMARIES=bt2020
ffsmart_build_hardware_args
ffsmart_build_filters
printf '%s\n' "${FFSMART_HW_INPUT_ARGS[@]}" | grep -Fxq -- 'vaapi=ffsmart:/dev/dri/renderD129'
printf '%s\n' "${FFSMART_FILTER_ARGS[@]}" | grep -Fq 'scale_vaapi=w=1280:h=720:format=nv12'

FFSMART_FORCE_SDR=true
FFSMART_OUTPUT_HEIGHT=1080
FFSMART_OUTPUT_WIDTH=1920
ffsmart_build_hardware_args
ffsmart_build_filters
! printf '%s\n' "${FFSMART_HW_INPUT_ARGS[@]}" | grep -Fxq -- '-hwaccel'
printf '%s\n' "${FFSMART_FILTER_ARGS[@]}" | grep -Fq 'zscale=t=linear'
printf '%s\n' "${FFSMART_FILTER_ARGS[@]}" | grep -Fq 'hwupload'

ffsmart_build_benchmark_command() { FFSMART_BENCH_CMD=(sleep 5); }
FFSMART_STATE_DIR="$test_dir"
CONCURRENCY_WALL_TIMEOUT=1
started="$(date +%s)"
if ffsmart_capacity_level_stable /dev/dri/renderD128 vaapi h264 0 1 10; then
    echo 'Capacity deadline unexpectedly accepted a timed-out job' >&2
    exit 1
fi
elapsed=$(( $(date +%s) - started ))
(( elapsed < 5 ))

echo 'Representative Main10 benchmark, selected-device policy, deadline, and hardware filter command tests passed'
