# Dependency Compatibility

## Production gate

The project has no required fork-only source dependency. Runtime compatibility
depends on the installed FFmpeg build exposing the codecs, filters, hardware
backends, and device access selected by the local capability scan.

## Last verified state

- Reviewed: `2026-09-21`.
- Runtime: FFmpeg and FFprobe 8.1.2 in the production Dispatcharr container.
- Shell: Bash 3 syntax gate plus production Linux Bash validation.
- Hardware: Intel integrated GPU and Intel Arc A310 through QSV and VAAPI.
- Required upstream pull requests: none.
- Managed beta.5 benchmark: completed at
  `2026-09-21T17:51:16.719376+00:00` with return code 0, valid cache, no lock,
  and no retained worker/run directories. Primary `renderD129` measured 19 at
  14x; secondary `renderD128` measured 14 at 11.6x.

## Contract matrix

| Dependency | Required contract | Status | Production conclusion |
|---|---|---|---|
| Bash | Arrays, process substitution, `BASH_SOURCE`, and Bash 3-compatible syntax | Covered by `bash -n`, pinned ShellCheck 0.11.0, and behavior tests | Compatible with Bash 3.2+ |
| FFmpeg | MPEG-TS muxing, selected encoders/decoders, filter graph, hardware-device initialization | Probed at runtime; all 16 bounded Intel QSV/VAAPI candidate combinations revalidated on FFmpeg 8.1.2 with hardware decoding | Conditional on local capability scan |
| FFprobe | Machine-readable stream metadata for video, audio, field order, color, and rates | Adaptive tiers tested against live and bounded inputs | Compatible on tested build |
| Linux DRM and `/proc` | Render-node identity and visible FFmpeg workload markers | Tested in Docker/LXC with two Intel devices | Optional; software fallback remains available |
| Standard Unix tools | `awk`, `grep`, `sed`, `sort`, `stat`, `mktemp`, `mkfifo`, `cat`, hashing and path helpers | Validation covers command construction, checked FIFO writers, and state lifecycle | Required as documented |

## Change review

### 2026-09-21 beta.4 source and managed validation review

Read-only inspection confirmed the managed host still runs FFmpeg 8.1.2 and
official Dispatcharr 0.31.0. Dispatcharr's loader, plugin API, and serializers
match upstream tag `v0.31.0` (commit
`bcbb68c4f054ee56383a41604cfcd7302b85da66`). The plugin bundles the wrapper by
immutable commit with per-file checksums; source publication alone does not
update an installed runtime. New hardware measurements and managed validation
were historical evidence for the source candidate. The exact beta.4 source,
archive, provenance, CI, native hardware, and bounded pipe evidence are closed
in `docs/beta4-validation-2026-09-21.md`. No live provider channel was fetched
and no actual profile was created.

Before changing the minimum runtime or claiming compatibility with a new
FFmpeg release, rerun the full behavior suite and representative software,
hardware, container, live-stream, and concurrency tests. Record the exact
version and environment here.

### 2026-09-21 CI and managed validation closure

GitHub runs `35631984969` and `35631983498` used the runner's ShellCheck 0.9
and failed on SC2218 reports that the official ShellCheck 0.11.0 release fixes.
CI replacement run `35633440274` passed with workflow definition
`10a6e4b8e16b66857df3b03a7bb6d0bb88fc9929`, pinning the official Linux x86_64
archive URL and SHA-256
`8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198`, printing
the installed version, and validating unchanged beta.4 source at
`913a958fd5f9edc231c49a70539a09f611fdcc5a`. Plugin tag CI `35631993818`,
plugin dev CI `35631991578`, and registry CI `35633913052` passed. The
managed beta.5 installation preserved settings and offered no update. The
final snapshot had zero viewers, zero input/output transcodes, no FFmpeg or
FFprobe processes, and an unchanged settings digest.
