# Changelog

All notable user-visible changes are documented here.

## Unreleased

## [0.1.0-beta.3] - 2026-09-07

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
