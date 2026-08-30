# Standalone parity validation — 2026-08-29

## Result

The standalone `ffmpeg-adaptive` runtime matched the accepted clean rewrite in
every deterministic, hardware, controlled-media, captured-stream, current-live,
scheduling, fallback, and performance comparison. All 22 same-input
rewrite/standalone media pairs were byte-for-byte identical, including every
transcode. No unintended behavior change was found in the move to the new
repository.

This report records validation only. It does not merge this branch, modify the
runtime, create a tag or release, deploy anything, change Dispatcharr, or update
a downstream pin.

## Immutable inputs and method

- Old baseline: `matrix2669/ffmpeg-asr`
  `7829924588336f1de07f18d944472c429a32c5b1`.
- Accepted clean rewrite: `matrix2669/ffmpeg-asr`
  `fe4fe93a4e1e5f81fb126a40739e123e4279f1dd`.
- Standalone repository under test: `matrix2669/ffmpeg-adaptive`
  `32567996dbf5ffe24f0df9bc559c1aad5817c061`.
- Workspace standards: `matrix2669/workspace`
  `4102563425631edef07899ed1cc8fc95423e05f6`.
- Reconciled standards revision:
  `sha256:6456d4a722cfca0a03e6bce3d698208c844a114953c62d0fe757789d48f1c794`.
- Evidence root on `iptv`:
  `/tmp/ffmpeg-adaptive-parity-20260829.SFpgVZ`.

Detached worktrees were used for all three exact commits. The production
checkout was not switched. A direct rewrite-to-standalone source review found
only the intended standalone changes: project identity/provenance, removal of
`-hdr`, `-10bit`, `-deinterlace`, and `-maxbitrate`, equivalent simplification
of automatic HDR/10-bit policy, and acceptance of the new
`FFMPEG_ADAPTIVE_FPS_FRAC` name alongside the compatibility variable. The two
benchmark entrypoints were identical.

## Safety and host inventory

Dispatcharr reported zero live, VOD, and catch-up clients before the live test
and again after it. No test container remained after validation. The only
remaining FFmpeg workload was a pre-existing `eplustv-proxy` copy/remux process;
it was not a Dispatcharr viewer, did not use `/dev/dri`, predated the test, and
was left untouched.

The test used the current Dispatcharr image
`sha256:e764cd3fb3a4b14e0c96eeb830cce645b44ef0a2494838e21462c71dde5abeb4`,
FFmpeg/FFprobe 8.1.2, Intel integrated graphics on `renderD128`, and Intel Arc
A310 on `renderD129`. Both render nodes were available in the unprivileged
container. Neither `intel_gpu_top` nor `vainfo` was installed, so engine-level
GPU telemetry was unavailable.

## Repository and capability gates

All repository suites passed in the Dispatcharr image:

| Tree | Result |
|---|---|
| Old baseline | `Validated ffmpeg-asr 1.1.0` |
| Accepted rewrite | `Validated ffmpeg-asr 1.1.1-beta.1` |
| Standalone | `Validated ffmpeg-adaptive 0.1.0`, including the removed-option contract |

Fresh rewrite and standalone capability scans produced the same substantive
schema-2 cache:

| Field | Rewrite | Standalone |
|---|---:|---:|
| Best path | VAAPI/H.264 low-power | VAAPI/H.264 low-power |
| Arc `renderD129` | capacity 14, speed 11.5x | capacity 14, speed 11.5x |
| iGPU `renderD128` | capacity 12, speed 11.1x | capacity 12, speed 11.1x |
| 10-bit decode/encode | true/true | true/true |

Normal wrapper startup reused both completed caches without starting another
benchmark. The resulting outputs were byte-identical. `benchmark-accel.sh 1 1`
also passed all 16 QSV/VAAPI, H.264/HEVC, normal/low-power combinations across
both nodes for both trees.

An interrupted exploratory explicit-recache reuse attempt left two lock files
only in the abandoned isolated `rewrite-fresh` and `standalone-fresh` state
directories. Explicit recache intentionally discards prior measurements, so
the attempt was stopped and not used as evidence. Completed caches were copied
to separate clean state directories for the valid reuse test. No production
state or active benchmark was affected; the two isolated files are retained
with the temporary evidence rather than deleted.

## Controlled and captured media

The matrix ran 66 wrapper cases: 48 controlled cases (16 policies across all
three trees) plus 18 cases using six policies against exact captures of real
1080p, 1080i, and 720p Dispatcharr sources.

- Every rewrite and standalone run returned status 0.
- The only old-baseline failures were the already documented HDR-to-SDR case
  (218) and finite-stdin replay case (183).
- All 82 non-empty artifacts across the full matrix and subsequent current-live
  run decoded successfully and had zero DTS backsteps.
- Rewrite and standalone had zero metadata mismatches.
- All 22 same-input rewrite/standalone pairs were byte-for-byte identical:
  16 controlled cases and six exact-capture cases, including all transcodes.
- Isolated no-DRI scans selected software HEVC for both trees; their actual
  H.264-to-HEVC outputs decoded and were byte-identical.

The exact current-source captures reused from the first comparison were:

| Source type | Bytes |
|---|---:|
| 1080p | 9,007,832 |
| 1080i | 11,149,904 |
| 720p | 5,668,012 |

## Current Dispatcharr streams

The live M3U exposed 515 channels at test time. Short metadata-only discovery
selected current sources by observed media:

| Source | Observed input |
|---|---|
| CBS 2 New York | H.264 High, 1920x1080 progressive, 60000/1001, AAC |
| PIX11 New York | MPEG-2 Main, 1920x1080 top-field-first, 30000/1001, AC-3 5.1 plus stereo |
| FOX 5 New York | H.264 High, 1280x720 progressive, 60000/1001, AAC |

Six bounded cases ran sequentially through old, rewrite, and standalone trees:
1080p copy and HEVC, 1080i progressive H.264 and HEVC with stereo conversion,
and 720p copy and HEVC. All 18 runs returned status 0 and all outputs decoded
with zero DTS backsteps. Rewrite and standalone metadata matched in every case.
Current-live files are not byte-comparable because each run necessarily
captured a different content window; the exact captures above provide the
same-input byte comparison.

Bounded elapsed time to completed output was:

| Case | Old | Rewrite | Standalone |
|---|---:|---:|---:|
| 1080p H.264 copy | 5.226 s | 3.929 s | 4.518 s |
| 1080p H.264 to HEVC | 6.445 s | 4.587 s | 4.612 s |
| 1080i to progressive H.264 | 17.556 s | 13.614 s | 13.507 s |
| 1080i to progressive HEVC | 16.352 s | 13.548 s | 13.948 s |
| 720p H.264 copy | 4.539 s | 4.056 s | 4.352 s |
| 720p H.264 to HEVC | 5.685 s | 4.836 s | 5.211 s |

These sequential observations are not latency benchmarks because provider
behavior and live content windows vary. No standalone result indicates a
material startup change from the accepted rewrite.

## Scheduling and performance

Three overlapping jobs produced the same weighted two-GPU choices for rewrite
and standalone: Arc for the first job, idle iGPU for the second, then Arc for
the third based on proportional visible load.

Five interleaved warm startup measurements were:

| Path | Median |
|---|---:|
| Direct FFmpeg | 23 ms |
| Old baseline | 98 ms |
| Accepted rewrite | 108 ms |
| Standalone | 107 ms |

The standalone difference from the rewrite was 1 ms in this sample. Three
alternating long-run repetitions removed a noisy first CPU snapshot:

| Metric | Rewrite median | Standalone median |
|---|---:|---:|
| CPU snapshot | 28.30% | 28.45% |
| Memory | 202.4 MiB | 202.5 MiB |
| FFmpeg throughput | 435 fps | 435 fps |
| Mux bitrate | 6,961.2 kbps | 6,958.5 kbps |
| PIDs | 39 | 39 |

The 0.15 percentage-point CPU and approximately 0.04% bitrate differences are
run noise; no performance regression was observed.

## Final audit and conclusion

The final privacy scan found no supported-scheme stream address and no embedded
credential in the saved logs. Final Dispatcharr client counts were 0/0/0, no
test container remained, and no test FFmpeg process remained.

The fresh source-overlap audit found no exact shared line of 32 or 48 characters
against the unlicensed upstream source. Against the mixed-rights historical
baseline, seven files contained one 32-character test-boilerplate line and no
file contained a 48-character shared line. This is unchanged from the accepted
provenance result and found no new substantive source overlap.

The repeat comparison therefore supports the expected conclusion: extracting
the accepted clean rewrite into `ffmpeg-adaptive` did not change runtime output,
hardware selection, fallback, scheduling, or measured performance. The only
observable differences are the intentional standalone identity, provenance,
environment-variable addition, and CLI removals already recorded in ADR-003.
