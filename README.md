# ffmpeg-adaptive

`ffmpeg-adaptive` is a self-contained Bash wrapper for normalizing live video
streams with FFmpeg. It probes the input, preserves compatible streams, chooses
an available hardware or software path, and writes MPEG-TS to standard output.

The implementation is independently organized and published under the MIT
License from a new Git history. See [PROVENANCE.md](PROVENANCE.md) for the
source and overlap audit.

## Highlights

- QSV, VAAPI, NVENC, VideoToolbox, V4L2 M2M, and software candidates.
- Physical-GPU discovery with explicit DRI, QSV, and VAAPI overrides.
- Capacity-aware selection across multiple visible GPUs.
- Adaptive input probing for live URLs and exact prefix replay for `pipe:0`.
- Independent video and audio copy/transcode decisions.
- Automatic HDR and 10-bit handling plus optional resolution, bitrate,
  channel, SDR, and deinterlace policies.
- A versioned data-only capability cache that is never sourced as shell code.
- Phase-scoped advanced FFmpeg arguments assembled as Bash arrays, without
  `eval`.
- Fixed MPEG-TS output to `pipe:1` for stream-profile integrations.

## Requirements

- Bash 3.2 or newer.
- `ffmpeg` and `ffprobe` available on `PATH`.
- Standard Unix tools used by the scripts, including `awk`, `grep`, `sed`,
  `sort`, `stat`, `mktemp`, `mkfifo`, and `cat`.
- The relevant GPU devices and FFmpeg encoders/decoders when hardware
  acceleration is desired.

The production validation recorded in this repository used FFmpeg 8.1.2 with
an Intel integrated GPU and Intel Arc A310. Capability and capacity results are
host-specific and must be generated on each installation.

After a successful rebuild, the configured state directory retains one
`benchmark-latest.log`. Individual worker diagnostics are consolidated only
after the capability cache is written; diagnostic creation, write, or read
failures return status 73 rather than silently selecting software encoding.
Each trial has a distinct log in a private run directory. Older worker logs and
failed-run directories are purged only after the new summary is published.
Failures before publication preserve diagnostic evidence for troubleshooting.
A failed cache write preserves the old cache; a later summary or cleanup failure
still fails the rebuild even if the new cache has already been saved.

## Quick start

Make the scripts executable and build the local capability cache:

```bash
chmod +x ffmpeg-smart.sh benchmark-accel.sh benchmark-live.sh
./ffmpeg-smart.sh --recache-only
```

Inspect the cache state:

```bash
./ffmpeg-smart.sh --cache-status
```

Normalize a stream to MPEG-TS on stdout:

```bash
./ffmpeg-smart.sh \
  -i INPUT_URL \
  -maxres 720 \
  -maxbr 2M \
  -maxchan 2 \
  -sdr \
  -deint \
  > output.ts
```

`ffmpeg-smart.sh` is retained as the compatibility command for existing
Dispatcharr profiles even though the standalone project is named
`ffmpeg-adaptive`.

## Common policy options

| Option | Behavior |
|---|---|
| `-vc h264\|hevc` | Require this video codec; convert only if the source or another policy requires it. |
| `-accel auto\|qsv\|vaapi\|nvenc\|videotoolbox\|v4l2m2m\|software` | Select or constrain acceleration. |
| `-sdr` | Convert HDR output to SDR when transcoding. |
| `-deint` | Deinterlace interlaced video; progressive video is left progressive. |
| `-maxres HEIGHT` | Set a maximum output height without upscaling. |
| `-maxbr BITRATE` | Set a video bitrate ceiling, such as `2M`. |
| `-maxchan COUNT` | Limit audio channels without upmixing. |
| `-device PATH` | Pin the shared DRI device. |
| `-qsv-device PATH` | Pin QSV to a render node. |
| `-vaapi-device PATH` | Pin VAAPI to a render node. |

Without `-vc`, H.264 and HEVC video is copied when it satisfies the active
resolution, bitrate, SDR and deinterlace requirements, regardless of the cached
preferred encoder. Other codecs (including unknown codec names) are normalized.
When conversion is needed, the cached codec preference chooses the encoder
(defaulting to H.264 if absent); `-vc` overrides that preference. `-accel` selects
an encoding backend and does not itself require conversion. Audio normalization
is independent: non-AAC audio or a channel-limit violation can convert while
video copies. `-maxbr` requires conversion when the video bitrate is unknown.

A profile can define its receiver's accepted copy codecs and conversion target:
`--copy-codecs h264,mpeg2 --fallback-codec h264` preserves H.264/MPEG-2
when other active constraints are satisfied and converts unsupported video to
H.264. Required resize, bitrate, deinterlace or SDR work uses that fallback
regardless of the cached codec. The universal defaults remain `h264,hevc` for
copy and the cached conversion preference. `--copy-codecs` takes a nonempty
comma-separated list of codec names;
case and surrounding/token whitespace are normalized. `mpeg2` is an alias for
`mpeg2video`, and both are supported. `--copy-codecs preferred` selects only the
current validated H.264/HEVC cache preference and cannot be mixed with names.
`--fallback-codec`
is optional and accepts `h264` or `hevc`.

Explicit `-vc h264|hevc` overrides both the copy list and fallback: it can force
conversion of an allowed codec or explicitly preserve another codec outside
the list. These controls govern video codec membership; audio, HDR and hardware
policy retain their existing controls. The operator must choose codecs the
receiver and MPEG-TS output support.

The environment variables `DRI_DEVICE`, `QSV_DEVICE`, and `VAAPI_DEVICE`
provide the same device controls. Explicit command-line values take
precedence.

HDR and 10-bit behavior is automatic: compatible HDR/10-bit input is
preserved when the selected path supports it, while `-sdr` explicitly requests
an SDR transcode. The removed `-hdr`, `-10bit`, `-deinterlace`, and
`-maxbitrate` spellings are rejected; use `-sdr`, `-deint`, and `-maxbr`.

## Experimental shared HTTP MPEG-TS input

For a known continuous HTTP(S) MPEG-TS source, opt into a single shared startup
reader so fast, expanded and default probing and final playback consume the
same incoming connection and retained opening bytes:

```bash
./ffmpeg-smart.sh --shared-input -i INPUT_URL > output.ts
```

`FFMPEG_SMART_SHARED_INPUT=true` enables the same behavior for managed callers.
It is **off by default** and requires Python 3.9+ plus private IPv4 loopback
access. No fixed prefill delay is added. One reader retains the original bytes
in RAM, replays byte zero to each probe, then delivers the exact prefix and
continuation to FFmpeg. Once playback consumes chunks, they are released. A
full queue applies backpressure; media is never dropped or spooled to disk.

| Environment setting | Default | Allowed values |
|---|---|---|
| `FFMPEG_SMART_SHARED_INPUT_BYTES` | 16777216 (16 MiB) | 65536..1073741824 retained payload bytes |
| `FFMPEG_SMART_SHARED_INPUT_DEADLINE` | 20 | 1..300 seconds until the first stdout media write |
| `FFMPEG_SMART_SHARED_INPUT_IDLE` | 30 | 1..300 seconds per blocking network operation |

The byte cap covers retained payload, with additional bounded read/write chunks
and OS buffers; it is not a process RSS limit or a media-duration target. Too
small a cap can starve a probe and fail the startup deadline. Telemetry on stderr
reports first source byte, per-tier request starts, playback feed, first output,
request counts and peak retained bytes without URLs or credentials. These
measure startup and queue behavior; they do not manage an ongoing time reservoir.

For a mixed-source managed profile, `--shared-input-auto` (or
`FFMPEG_SMART_SHARED_INPUT=auto`) inspects eligible direct HTTP(S) response bytes,
including URLs without a `.ts` suffix or format query. The first 377 bytes must
have MPEG-TS sync bytes at offsets 0, 188 and 376. MIME labels are not trusted:
valid TS is retained and replayed from the same open response, even if its MIME
type is missing or misleading. No separate detection request or prefill is used.

Known `.m3u8` paths, other protocols, custom input-option tokens, ambient
protocol/all proxy variables and unavailable Python keep legacy handling.
Auto conservatively bypasses shared acquisition whenever a proxy variable is
nonempty, even with no_proxy, because direct helper HTTP semantics cannot
establish transport equivalence. Path suffix matching is case-insensitive.

If Auto encounters a non-TS body (including an opaque HLS playlist), it closes
that classification response before starting any probe or emitting media, then
runs the existing FFmpeg path on the original source URL and environment.
Relative playlist URLs, authentication and demuxing stay with FFmpeg. This
compatibility fallback may open a non-TS source again; it never reopens validated
TS. A short non-TS body or compressed response can also fall back. Network,
HTTP-status, redirect-security, truncated-body and startup-deadline failures do
not trigger fallback or retries. The same startup watchdog covers classification
and the legacy child. `auto_fallback=non-ts` identifies this path, and its
`shared-input classification` counters cover only the detection request, not
subsequent legacy requests.

Only continuous 188-byte MPEG-TS uses the shared broker. Explicit
`--shared-input` remains strict and fails on unsupported input without fallback;
Off retains the existing acquisition path without classification. After TS has
been accepted, failures never trigger another media reader or fallback open.
At most five HTTP redirects precede the media response. Cross-origin redirects
strip Basic Authorization; HTTPS downgrade and credentials in redirect URLs
fail. For shared TS, `upstream_opens` counts accepted media responses (at most
one), while `upstream_requests` includes redirect handshakes.

The dedicated `-user_agent` option and URL Basic authentication are supported.
Owned FFprobe/FFmpeg broker clients clear inherited proxy settings and bypass
proxies for loopback, keeping the private broker URL/token inside the session.
This applies only after shared input is explicitly selected.
All `-ffmpeg-input-option` arguments are rejected before acquisition, including
custom headers/cookies/authentication, rather than silently ignored. Python uses
direct connections and system TLS trust; FFmpeg-specific proxy and transport
semantics are not inherited. Other advanced phases, input add/replace policy,
explicit `-vc`, independent audio normalization, cache requirements and the
opt-in degraded proxy retain their existing policy. Strict shared input rejects compressed HTTP bodies. Read failures, truncated
bodies and timeouts fail clearly without reconnect in both shared modes.

This is an experimental source feature. Include `lib/ffsmart-shared-input.py`
in installed packages and downstream checksum manifests. Production installation,
live startup comparisons and any default-profile rollout require separate tests.
The downstream playback reservoir is separate and unchanged.

## State and managed integrations

Standalone use stores state beside the script. Replaceable installations
should set a persistent directory:

```bash
export FFMPEG_SMART_STATE_DIR=/data/ffmpeg_smart_profiles
```

Managed callers may require a valid cache:

```bash
export FFMPEG_SMART_REQUIRE_CACHE=true
```

They may also opt into degraded stream-copy service while a cache is missing,
invalid, stale, or being rebuilt:

```bash
export FFMPEG_SMART_CACHE_FALLBACK=proxy
export FFMPEG_SMART_FALLBACK_MARKER=/data/ffmpeg_smart_profiles/fallback.marker
```

The fallback is intentionally opt-in. It bypasses adaptive policy and hardware
acceleration until a valid capability cache is available.

## Advanced FFmpeg arguments

Advanced options are added one argument at a time in an explicit phase:

- `-ffmpeg-input-option`
- `-ffmpeg-map`
- `-ffmpeg-video-option`
- `-ffmpeg-audio-option`
- `-ffmpeg-mux-option`

Each phase supports `inherit`, `add`, or `replace` through its matching mode
option. Mapping also supports `all`. The wrapper retains ownership of the
input, hardware device, video encoder, hardware filter graph, and final
`-f mpegts pipe:1` destination.

When managed audio is transcoded, a simple added `dynaudnorm` filter composes
after `aresample=async=1` rather than replacing it. For example, add
`-af` and `dynaudnorm=f=150:g=15` as separate audio-option arguments. The last
matching user filter wins before composition. Replacement mode stays entirely
operator-controlled. Other graphs retain FFmpeg’s last-option behavior; adding
a filter to copied audio still requires explicitly choosing an encoder.

Known six-channel `5.1(side)` streams encoded as AAC use one-to-one surround
routing into standard `5.1` (back) so ADTS headers identify all six channels at
late join. Channel count, sample rate and bitrate policy are preserved. Stereo,
other layouts, copied AAC and replacement audio policy are unaffected. Unknown
mappings or layout-changing filter graphs conservatively skip this correction.

## Benchmarks

`benchmark-accel.sh` records candidate results. `benchmark-live.sh` exercises
the production wrapper against a local or live input. QSV and VAAPI capacity
tests use the same hardware-decoder initialization as production transcodes,
and each cached capacity is tied to that device's measured accelerator, codec,
low-power mode, and 10-bit capabilities. Capacity results are not portable
defaults: rerun the capability scan after hardware, driver, FFmpeg, container,
or host changes.

## Validation

Run the complete shell and behavior gate:

```bash
./scripts/validate.sh
```

Hardware and integration changes also require real FFmpeg tests on the target
host. The initial Intel, Docker/LXC, live-stream, 1080p, 1080i, and 720p results
are recorded in [docs/validation-2026-08-29.md](docs/validation-2026-08-29.md).
The repeat comparison against the standalone repository is recorded in
[docs/standalone-parity-validation-2026-08-29.md](docs/standalone-parity-validation-2026-08-29.md).

The beta.4 release-source validation is recorded in
[docs/beta4-validation-2026-09-21.md](docs/beta4-validation-2026-09-21.md).
That record separates the immutable wrapper source at `913a958` from the CI
workflow definition at `10a6e4b`, includes the inspected archive checksum and
provenance audit, and records the completed native benchmark, bounded real-
hardware pipe test, and final zero-viewer/process snapshot.

## License

Copyright 2026 Jarred Saperton. Licensed under the [MIT License](LICENSE).
