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

### Experimental shared-input runtime contract (2026-10-30)

`--shared-input` additionally requires Python 3.9+ with the standard library,
POSIX process groups and an available private IPv4 loopback listener. Its helper
is `lib/ffsmart-shared-input.py`; include it in installable archives and every
downstream immutable per-file checksum manifest alongside the Bash modules.
The feature is off by default. `--shared-input-auto` uses conservative URL hints
and bypasses optimization when Python or supported input conditions are absent.
Python direct HTTP(S), system TLS trust, user-agent and URL Basic authentication are the supported transport contract;
advanced FFmpeg input options are rejected rather than ignored. Five bounded
redirects are allowed, without cross-origin Authorization or HTTPS downgrade.
Only one successful MPEG-TS media body is consumed; reconnect is forbidden.
Local validation uses generated media and fixture servers. It does not establish
production Python/FFmpeg compatibility or live startup performance; see ADR-018.
The complete development validation suite now requires Python 3.9+ and loopback
network permission to execute these deterministic local fixture tests.


### Beta.3 eligibility and preferred policy

Auto now bypasses shared input when any case variant of HTTP/HTTPS/ALL/FTP/SOCKS
proxy configuration is nonempty. No transport equivalence or Dispatcharr timeout
inheritance is claimed. Preferred-copy selection resolves the current validated
H.264/HEVC cache preference; it is never stored as a fixed deployment codec.
Public `mpeg2` aliases `mpeg2video`, with normalized CSV whitespace/case. See
ADR-020. Local fixture cancellation covers both probing and playback under the
plugin's planned 10-second startup and 30-second internal network guards.

### Unhinted response classification (2026-10-30)

ADR-021 supersedes the URL-hint-only Auto limitation above. Direct HTTP(S) opaque
URLs are classified from the retained body; valid 188-byte TS uses one upstream
media response regardless of MIME. Non-TS returns to the original FFmpeg URL
before probes/output, with classification-only counters and the same deadline.
Known HLS/proxy/custom-input bypasses and strict mode remain unchanged. Real
local HLS validation includes Basic auth, redirect and relative segment handling;
live provider and installed downstream validation remain separate.
