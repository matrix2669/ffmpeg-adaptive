# Changelog

All notable user-visible changes are documented here.

## Unreleased

### CI maintenance

- CI replacement run `35633440274` passed with workflow definition
  `10a6e4b8e16b66857df3b03a7bb6d0bb88fc9929`, validating unchanged beta.4
  source commit `913a958fd5f9edc231c49a70539a09f611fdcc5a`. Historical failed
  runs `35631984969` and `35631983498` remain recorded as ShellCheck 0.9
  SC2218 false-positive failures, not release evidence.

### Validation status

- The plugin tag CI passed as `35631993818`; the development plugin CI passed
  as `35631991578`; and registry CI `35633913052` validated the registry
  checkout. Published root and detail endpoints were independently verified.
  The managed beta.5 installation preserved settings and
  offered no update while no viewers were active.
- Native benchmark validation completed at `2026-09-21T17:51:16.719376+00:00`
  with return code 0, a valid cache, no lock, and no retained root worker logs
  or run directories. The primary `renderD129` measured capacity 19 at 14x;
  secondary `renderD128` measured capacity 14 at 11.6x, with VAAPI/HEVC Main10
  decode and encode support.
- A bounded real-hardware launcher test sent a previously generated four-second
  H.264 fixture through `pipe:0` to HEVC VAAPI 720p output for 4.025 seconds;
  full decode with `-xerror` completed without errors and measured 120 frames. No live-provider
  channel was fetched and no actual profile was created.
- The final `17:52:25` snapshot had zero viewers, zero input/output transcodes,
  no FFmpeg/FFprobe processes, the beta.5 runtime and manifest pinned to
  `913a958`, and an unchanged settings digest.

## [0.1.0-beta.4] - 2026-09-21

### Fixed

- Hardened benchmark diagnostics: status-73 I/O
  propagation, checked post-create stderr persistence, unique private run logs,
  atomic summary publication before retention cleanup, cache-write preservation,
  contained cleanup, and bounded capacity-worker termination.

## [0.1.0-beta.3] - 2026-09-07

The subsequent review found that the intended guarantees below were incomplete:
subshells lost failure state and some persistence failures still reported success.
Beta.4 repairs these boundaries and adds failure-injection coverage.

### Fixed

- Fail a hardware-cache rebuild when benchmark diagnostics cannot be written,
  rather than saving a software-only result as a completed hardware benchmark.
- Retain one consolidated `benchmark-latest.log` after a successful rebuild and
  remove older per-worker benchmark diagnostics.

## [0.1.0-beta.2] - 2026-08-30

### Fixed

- Made QSV and VAAPI capacity measurements use the same hardware-decoder
  initialization and hardware-frame path as normal transcodes instead of
  combining software decode with hardware upload.
- Preferred devices measured for the requested accelerator and codec, used a
  conservative capacity of one when no exact path was measured, and applied
  the selected device's own low-power and 10-bit-encode capabilities at
  runtime.
- Rebenchmarked compatible secondary GPUs on the globally selected
  accelerator/codec before capacity measurement, so automatic multi-GPU
  scheduling never combines capacities measured under different codecs.
- Advanced the capacity-policy fingerprint so caches produced by the earlier
  benchmark command are reported stale and rebuilt before managed use.
- Added a wall-clock deadline to every concurrent capacity level so a severely
  oversubscribed hardware probe is rejected and terminated instead of waiting
  indefinitely for its requested media duration.
- Changed capacity upper-bound discovery from 100% to 50% growth per step,
  reducing deliberate oversubscription while retaining exact binary-search
  boundary selection.

### Validation

- Passed all 16 bounded QSV/VAAPI, H.264/HEVC, normal/low-power candidate
  combinations across the production Intel iGPU and Arc A310 with hardware
  decoding active.
- Confirmed the common VAAPI/HEVC path at 18 simultaneous streams on Arc and
  14 on the iGPU, including 30-second accepted/rejected boundary checks.
- Passed current Dispatcharr 1080p, 1080i, 720p, `pipe:0`, decoded-frame
  deinterlace, timestamp, and staggered two-GPU scheduling validation.

## [0.1.0-beta.1] - 2026-08-30

### Validation

- Repeated the complete baseline/rewrite comparison against the standalone
  repository, including current Dispatcharr 1080p, 1080i, and 720p streams;
  found no unintended behavioral, media, scheduling, or performance change.

### Added

- Independent modular FFmpeg normalization runtime with Bash 3 compatibility.
- Adaptive live-input probing and exact non-seekable input replay.
- Data-only capability cache, per-device capability discovery, real concurrent
  capacity testing, and proportional multi-GPU selection.
- QSV, VAAPI, NVENC, VideoToolbox, V4L2 M2M, and software candidate paths.
- Independent video/audio policy, composable output constraints, auxiliary
  stream mapping, phase-scoped advanced arguments, and MPEG-TS stdout output.
- Behavioral regression suite and live validation across H.264 1080p59.94,
  MPEG-2 1080i29.97, and H.264 720p59.94 Dispatcharr sources.
- MIT licensing, clean project history, and an evidence-backed provenance
  record.
