# Changelog

All notable user-visible changes are documented here.

## Unreleased

### Validation

- Repeated the complete baseline/rewrite comparison against the standalone
  repository, including current Dispatcharr 1080p, 1080i, and 720p streams;
  found no unintended behavioral, media, scheduling, or performance change.

## [0.1.0] - 2026-08-29

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
