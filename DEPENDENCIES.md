# Dependency Compatibility

## Production gate

The project has no required fork-only source dependency. Runtime compatibility
depends on the installed FFmpeg build exposing the codecs, filters, hardware
backends, and device access selected by the local capability scan.

## Last verified state

- Reviewed: `2026-08-29`.
- Runtime: FFmpeg and FFprobe 8.1.2 in the production Dispatcharr container.
- Shell: Bash 3 syntax gate plus production Linux Bash validation.
- Hardware: Intel integrated GPU and Intel Arc A310 through QSV and VAAPI.
- Required upstream pull requests: none.

## Contract matrix

| Dependency | Required contract | Status | Production conclusion |
|---|---|---|---|
| Bash | Arrays, process substitution, `BASH_SOURCE`, and Bash 3-compatible syntax | Covered by `bash -n`, ShellCheck, and behavior tests | Compatible with Bash 3.2+ |
| FFmpeg | MPEG-TS muxing, selected encoders/decoders, filter graph, hardware-device initialization | Probed at runtime and validated on FFmpeg 8.1.2 | Conditional on local capability scan |
| FFprobe | Machine-readable stream metadata for video, audio, field order, color, and rates | Adaptive tiers tested against live and bounded inputs | Compatible on tested build |
| Linux DRM and `/proc` | Render-node identity and visible FFmpeg workload markers | Tested in Docker/LXC with two Intel devices | Optional; software fallback remains available |
| Standard Unix tools | `awk`, `grep`, `sed`, `sort`, `stat`, `mktemp`, hashing and path helpers | Validation covers command construction and state lifecycle | Required as documented |

## Change review

Before changing the minimum runtime or claiming compatibility with a new
FFmpeg release, rerun the full behavior suite and representative software,
hardware, container, live-stream, and concurrency tests. Record the exact
version and environment here.
