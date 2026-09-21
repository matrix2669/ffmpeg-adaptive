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
| `-vc h264\|hevc` | Request the target video codec. |
| `-accel auto\|qsv\|vaapi\|nvenc\|videotoolbox\|v4l2m2m\|software` | Select or constrain acceleration. |
| `-sdr` | Convert HDR output to SDR when transcoding. |
| `-deint` | Deinterlace interlaced video; progressive video is left progressive. |
| `-maxres HEIGHT` | Set a maximum output height without upscaling. |
| `-maxbr BITRATE` | Set a video bitrate ceiling, such as `2M`. |
| `-maxchan COUNT` | Limit audio channels without upmixing. |
| `-device PATH` | Pin the shared DRI device. |
| `-qsv-device PATH` | Pin QSV to a render node. |
| `-vaapi-device PATH` | Pin VAAPI to a render node. |

The environment variables `DRI_DEVICE`, `QSV_DEVICE`, and `VAAPI_DEVICE`
provide the same device controls. Explicit command-line values take
precedence.

HDR and 10-bit behavior is automatic: compatible HDR/10-bit input is
preserved when the selected path supports it, while `-sdr` explicitly requests
an SDR transcode. The removed `-hdr`, `-10bit`, `-deinterlace`, and
`-maxbitrate` spellings are rejected; use `-sdr`, `-deint`, and `-maxbr`.

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

## License

Copyright 2026 Jarred Saperton. Licensed under the [MIT License](LICENSE).
