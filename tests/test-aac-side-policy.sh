#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd -P)"
source "$repo/lib/ffsmart-probe.sh"
source "$repo/lib/ffsmart-policy.sh"
ffsmart_log() { :; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/probe" <<'DATA'
index=10|codec_type=audio|codec_name=ac3|channels=6|sample_rate=48000|channel_layout=5.1(side)
index=2|codec_type=audio|codec_name=ac3|channels=2|sample_rate=48000|channel_layout=stereo
index=1|codec_type=audio|codec_name=ac3|channels=6|sample_rate=48000|channel_layout=5.1
index=10|codec_type=audio|codec_name=ac3|channels=6|sample_rate=48000|channel_layout=5.1(side)
DATA
ffsmart_parse_probe_output "$tmp/probe"
[[ "${FFSMART_AUDIO_INDEXES[*]}" == '1 2 10' ]]
FFSMART_AUDIO_MODE=inherit; FFSMART_USER_AUDIO_ARGS=(); FFSMART_MAX_CHANNELS=''; FFSMART_MAP_ARGS=(-map 0)
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:2 pan=5.1|'* ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'aresample=async=1'* ]]
FFSMART_MAP_ARGS=(-map 0:a:2 -map 0:a:1 -map 0:a:2)
FFSMART_AUDIO_MODE=add; FFSMART_USER_AUDIO_ARGS=(-af 'dynaudnorm=f=150:g=15')
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:0 pan=5.1|'*',dynaudnorm=f=150:g=15'* ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:2 pan=5.1|'* ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:0 pan=5.1|'*',aresample=async=1,dynaudnorm=f=150:g=15'* ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:1 aresample=async=1,dynaudnorm=f=150:g=15'* ]]
FFSMART_MAP_ARGS=(-map 0)
FFSMART_USER_AUDIO_ARGS=(-af dynaudnorm=f=150:g=15 -filter:a:1 dynaudnorm=f=200:g=7)
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:0 aresample=async=1,dynaudnorm=f=150:g=15'* ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:1 aresample=async=1,dynaudnorm=f=200:g=7'* ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:2 pan=5.1|'*',aresample=async=1,dynaudnorm=f=150:g=15'* ]]
FFSMART_USER_AUDIO_ARGS=(-filter:a:1 dynaudnorm=f=200:g=7 -af dynaudnorm=f=150:g=15)
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:1 aresample=async=1,dynaudnorm=f=150:g=15'* ]]
FFSMART_USER_AUDIO_ARGS=(-c:a:1 copy -af dynaudnorm=f=150:g=15)
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'-filter:a:1 aresample=async=1,dynaudnorm'* ]]
FFSMART_USER_AUDIO_ARGS=(-af 'dynaudnorm=f=150:g=15')
FFSMART_MAX_CHANNELS=2; ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_MAX_CHANNELS=6; FFSMART_USER_AUDIO_ARGS=(-c:a copy); ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_USER_AUDIO_ARGS=(-c:a ac3); ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_USER_AUDIO_ARGS=(-af 'pan=stereo|c0=c0|c1=c1'); ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_AUDIO_MODE=replace; FFSMART_USER_AUDIO_ARGS=(-c:a aac -af 'dynaudnorm=f=150:g=15'); ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_AUDIO_MODE=inherit; FFSMART_USER_AUDIO_ARGS=(); FFSMART_AUDIO_ALL_AAC=true; ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
for pair in mono:1 stereo:2 5.1:6 unknown:6 7.1:8; do
    FFSMART_AUDIO_LAYOUTS[2]="${pair%:*}"; FFSMART_AUDIO_CHANNELS[2]="${pair#*:}"; FFSMART_AUDIO_ALL_AAC=false; ffsmart_resolve_audio_policy
    [[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
done
FFSMART_AUDIO_CHANNELS[2]=6; FFSMART_AUDIO_LAYOUTS[2]='5.1(side)'
FFSMART_MAP_ARGS=(-map 0 -map -0:a:2 -map 0:a:2)
ffsmart_resolve_audio_policy
[[ "${FFSMART_MAPPED_AUDIO[*]}" == '0 1 2' ]]
FFSMART_MAP_ARGS=(-map 0 -map -0:a:2)
ffsmart_resolve_audio_policy
[[ "${FFSMART_MAPPED_AUDIO[*]}" == '0 1' ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_MAP_ARGS=(-map 0 -map -0:10)
ffsmart_resolve_audio_policy
[[ "${FFSMART_MAPPED_AUDIO[*]}" == '0 1' ]]
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_MAP_ARGS=(-map 0 -map -0:a:2 -map 0:a:2)
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:2 pan=5.1|'* ]]
FFSMART_MAP_ARGS=(-map 0)
FFSMART_USER_AUDIO_ARGS=(-ac:a:2 2)
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
FFSMART_USER_AUDIO_ARGS=(-ac:a:1 2)
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" == *'-filter:a:2 pan=5.1|'* ]]
FFSMART_USER_AUDIO_ARGS=()
FFSMART_MAP_ARGS=(-map '0:a:m:language:eng')
ffsmart_resolve_audio_policy
[[ "${FFSMART_AUDIO_ARGS[*]}" != *'pan=5.1'* ]]
printf 'AAC side-layout policy tests passed\n'
