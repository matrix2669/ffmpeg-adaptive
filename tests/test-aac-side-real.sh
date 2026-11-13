#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd -P)"
source "$repo/tests/test-helper.sh"
tmp="$(mktemp -d)"
cleanup() {
    local status=$?
    if (( status != 0 )) && [[ -f "$tmp/mixed.log" ]]; then cat "$tmp/mixed.log" >&2; fi
    rm -rf "$tmp"
}
trap cleanup EXIT
mkdir "$tmp/state"
test_write_valid_cache "$repo" "$tmp/state"
for rate in 48000 44100; do
    ffmpeg -v error -f lavfi -i 'testsrc2=size=160x90:rate=10' -f lavfi -i "aevalsrc=0.1*sin(2*PI*311*t)|0.1*sin(2*PI*421*t)|0.1*sin(2*PI*523*t)|0.1*sin(2*PI*83*t)|0.1*sin(2*PI*733*t)|0.1*sin(2*PI*887*t):s=$rate:c=5.1(side)" -t 12 -c:v mpeg2video -c:a ac3 -b:a 384k -f mpegts "$tmp/input.ts"
    ffmpeg -v error -i "$tmp/input.ts" -map 0:v:0 -map 0:a:0 -c:v copy -c:a aac -b:a 384k -af aresample=async=1 -f mpegts "$tmp/baseline.ts"
    ffmpeg -v error -i "$tmp/baseline.ts" -map 0:a:0 -f null -
    ffmpeg -v error -i "$tmp/baseline.ts" -map 0:a:0 -c:a copy -f adts "$tmp/baseline.aac"
    FFMPEG_SMART_STATE_DIR="$tmp/state" FFMPEG_SMART_REQUIRE_CACHE=true "$repo/ffmpeg-smart.sh" -i "$tmp/input.ts" --copy-codecs mpeg2 > "$tmp/output.ts" 2> "$tmp/log"
    [[ "$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate,channels,channel_layout -of csv=p=0 "$tmp/output.ts" | head -1)" == "$rate,6,5.1" ]]
    ffmpeg -v error -i "$tmp/output.ts" -map 0:a:0 -f null -
    ffmpeg -v error -i "$tmp/output.ts" -map 0:a:0 -t 1 -f f32le "$tmp/audio.pcm"
    ffmpeg -v error -i "$tmp/input.ts" -map 0:a:0 -t 1 -f f32le "$tmp/source.pcm"
    python3 - "$tmp/audio.pcm" "$rate" "$tmp/source.pcm" <<'PYCODE'
import array, math, sys
samples = array.array('f'); samples.fromfile(open(sys.argv[1], 'rb'), 6 * int(sys.argv[2]) // 2)
source = array.array('f'); source.fromfile(open(sys.argv[3], 'rb'), len(samples))
rate = int(sys.argv[2]); tones = [311, 421, 523, 83, 733, 887]
for channel in range(6):
    data = samples[channel::6]
    powers = []
    for frequency in tones:
        re = sum(x * math.cos(2*math.pi*frequency*i/rate) for i,x in enumerate(data))
        im = sum(x * math.sin(2*math.pi*frequency*i/rate) for i,x in enumerate(data))
        powers.append(math.hypot(re, im))
    assert powers[channel] > 5 * max(p for j,p in enumerate(powers) if j != channel), (channel, powers)
    original = source[channel::6]; frequency = tones[channel]
    re = sum(x * math.cos(2*math.pi*frequency*i/rate) for i,x in enumerate(original))
    im = sum(x * math.sin(2*math.pi*frequency*i/rate) for i,x in enumerate(original))
    ratio = powers[channel] / math.hypot(re, im)
    assert 0.7 < ratio < 1.3, (channel, ratio)
PYCODE
    for fraction in 2 3 4; do
        python3 - "$tmp/baseline.ts" "$tmp/baseline-late.ts" "$fraction" <<'PYCODE'
import sys
b=open(sys.argv[1], 'rb').read(); offset=(len(b)//int(sys.argv[3])//188)*188
open(sys.argv[2], 'wb').write(b[offset:])
PYCODE
        baseline_info="$(ffprobe -v quiet -select_streams a:0 -show_entries stream=sample_rate,channels -of csv=p=0 "$tmp/baseline-late.ts" | head -1 || true)"
        [[ "$baseline_info" != "$rate,6" ]]

        python3 - "$tmp/output.ts" "$tmp/late.ts" "$fraction" <<'PYCODE'
import sys
b=open(sys.argv[1], 'rb').read(); offset=(len(b)//int(sys.argv[3])//188)*188
open(sys.argv[2], 'wb').write(b[offset:])
PYCODE
        [[ "$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate,channels -of csv=p=0 "$tmp/late.ts" | head -1)" == "$rate,6" ]]
        ffmpeg -v error -xerror -i "$tmp/late.ts" -map 0:a:0 -f null -
    done
    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$tmp/output.ts" | grep -q mpeg2video
    ffmpeg -v error -i "$tmp/output.ts" -map 0:a:0 -c:a copy -f adts "$tmp/fixed.aac"
    python3 - "$tmp/baseline.aac" "$tmp/fixed.aac" <<'PY'
import sys
for path, expected in zip(sys.argv[1:], (0, 6)):
    b = open(path, 'rb').read()
    assert b[0] == 255 and b[1] & 0xf6 == 0xf0
    config = ((b[2] & 1) << 2) | (b[3] >> 6)
    assert config == expected, (path, config, expected)
PY
    rm "$tmp/input.ts" "$tmp/output.ts" "$tmp/audio.pcm" "$tmp/source.pcm" "$tmp/late.ts" "$tmp/baseline.ts" "$tmp/baseline-late.ts" "$tmp/baseline.aac" "$tmp/fixed.aac"
done
# Exercise Add normalization on a mixed source. AC-3 supplies side layout;
# lossless FLAC retains canonical back and stereo input layouts in Matroska.
ffmpeg -v error -f lavfi -i 'testsrc2=size=160x90:rate=10' \
    -f lavfi -i 'aevalsrc=0.1*sin(2*PI*311*t)|0.1*sin(2*PI*421*t)|0.1*sin(2*PI*523*t)|0.1*sin(2*PI*83*t)|0.1*sin(2*PI*733*t)|0.1*sin(2*PI*887*t):s=48000:c=5.1(side)' \
    -f lavfi -i 'aevalsrc=0.1*sin(2*PI*311*t)|0.1*sin(2*PI*421*t)|0.1*sin(2*PI*523*t)|0.1*sin(2*PI*83*t)|0.1*sin(2*PI*733*t)|0.1*sin(2*PI*887*t):s=48000:c=5.1' \
    -f lavfi -i 'sine=frequency=440:sample_rate=48000' \
    -t 3 -map 0:v -map 1:a -map 2:a -map 3:a -c:v mpeg2video \
    -c:a:0 ac3 -c:a:1 flac -c:a:2 flac -ac:a:2 2 "$tmp/mixed.mkv"
FFMPEG_SMART_STATE_DIR="$tmp/state" FFMPEG_SMART_REQUIRE_CACHE=true "$repo/ffmpeg-smart.sh" \
    -i "$tmp/mixed.mkv" --copy-codecs mpeg2 -ffmpeg-map-mode all \
    -ffmpeg-audio-mode add -ffmpeg-audio-option -af -ffmpeg-audio-option dynaudnorm=f=150:g=15 \
    > "$tmp/mixed.ts" 2> "$tmp/mixed.log"
for spec in '0:6:5.1' '1:6:5.1' '2:2:stereo'; do
    IFS=: read -r ordinal channels layout <<< "$spec"
    [[ "$(ffprobe -v error -select_streams "a:$ordinal" -show_entries stream=sample_rate,channels,channel_layout -of csv=p=0 "$tmp/mixed.ts" | head -1)" == "48000,$channels,$layout" ]]
    ffmpeg -v error -xerror -i "$tmp/mixed.ts" -map "0:a:$ordinal" -f null -
done
# A compatible AAC-only source stays on the copy path without an added filter.
ffmpeg -v error -i "$tmp/mixed.ts" -map 0:v:0 -map 0:a:2 -c copy "$tmp/aac-only.ts"
FFMPEG_SMART_STATE_DIR="$tmp/state" FFMPEG_SMART_REQUIRE_CACHE=true "$repo/ffmpeg-smart.sh" \
    -i "$tmp/aac-only.ts" --copy-codecs mpeg2 > "$tmp/copied.ts" 2> "$tmp/copied.log"
ffmpeg -v error -i "$tmp/aac-only.ts" -map 0:a:0 -c copy -f adts "$tmp/original.aac"
ffmpeg -v error -i "$tmp/copied.ts" -map 0:a:0 -c copy -f adts "$tmp/copied.aac"
cmp "$tmp/original.aac" "$tmp/copied.aac"
# Explicitly adding a filter to a copy-only output remains an FFmpeg error.
if FFMPEG_SMART_STATE_DIR="$tmp/state" FFMPEG_SMART_REQUIRE_CACHE=true "$repo/ffmpeg-smart.sh" \
    -i "$tmp/aac-only.ts" --copy-codecs mpeg2 -ffmpeg-audio-mode add \
    -ffmpeg-audio-option -af -ffmpeg-audio-option dynaudnorm=f=150:g=15 \
    > "$tmp/invalid-copy.ts" 2> "$tmp/invalid-copy.log"; then
    printf 'Expected FFmpeg to reject filtering an audio stream copy\n' >&2
    exit 1
fi
grep -Eiq 'filter.*(copy|streamcopy)|(copy|streamcopy).*filter' "$tmp/invalid-copy.log"
printf 'Real FFmpeg side-layout and Add-normalization tests passed\n'
