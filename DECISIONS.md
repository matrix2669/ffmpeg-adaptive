# Decisions

---

# ADR-001: Publish as a clean standalone MIT project

## Status

Accepted

## Date

2026-08-29

## Decision

Create `matrix2669/ffmpeg-adaptive` as a standalone repository with a new Git
history and an MIT license. Import only the independently structured rewrite,
new behavioral tests, matrix2669-owned validation evidence, and newly authored
standalone documentation. Do not import inherited Git objects or inherited
README/governance text from `FiveBoroughs/ffmpeg-asr`.

## Reason

The previous fork's upstream source has no identified license, and an open MIT
pull request is not permission. The completed replacement runtime has no
non-trivial exact source overlap, but a clean repository removes ambiguous
history and lets the owner license only the independently authored tree.

## Alternatives considered

- Add MIT to the existing fork: rejected because its history and documentation
  contain unlicensed upstream expression.
- Wait indefinitely for the upstream license request: rejected because the
  independent rewrite and provenance evidence provide a controllable path.
- Remove attribution/history evidence: rejected because transparent provenance
  is part of the acceptance gate.

## Consequences

The new project owns its branch and release lifecycle. The old fork remains a
comparison and provenance record and is not merged into this history. A source
overlap and ownership review remains a release gate; this ADR is not a legal
opinion.

## Provenance

- Rewrite source checkpoint: `matrix2669/ffmpeg-asr` commit `fe4fe93a4e1e5f81fb126a40739e123e4279f1dd`
- Independent runtime commit: `300a4707903c15f53c05b8ec8a379cf8fa22c2b5`
- Workspace sidecar: `matrix2669/workspace` commit `4102563425631edef07899ed1cc8fc95423e05f6`
- Source conversation: `Copyright and Code Overlap Review`

---

# ADR-002: Confirm the bootstrap identity and compatibility command

## Status

Accepted

## Date

2026-08-29

## Decision

Name the standalone project `ffmpeg-adaptive` while retaining
`ffmpeg-smart.sh` as the executable compatibility command. Existing
`FFMPEG_SMART_*` managed-integration variables remain stable in version 0.1.0.

Publish the repository publicly as `matrix2669/ffmpeg-adaptive`, use initial
version `0.1.0`, and identify `Jarred Saperton` as the 2026 copyright holder.

## Reason

Dispatcharr profiles and the related plugin already call that filename and use
those variables. Renaming the repository does not require an immediate breaking
integration migration.

## Alternatives considered

- Rename the executable and every variable immediately: deferred because it
  would add unrelated integration risk to the licensing/history move.
- Provide two full implementations: rejected because it would create duplicate
  sources of truth.

## Consequences

User-facing branding and the executable name differ. Revisit when downstream
integrations can migrate atomically; if renamed later, keep a thin compatibility
entry point for at least one major version.

## Confirmation

The owner explicitly confirmed the public repository, copyright holder,
initial version, and compatibility-command assumptions on 2026-08-29 after the
bootstrap checkpoint.

---

# ADR-003: Make HDR and 10-bit automatic and keep one spelling per policy

## Status

Accepted

## Date

2026-08-29

## Decision

HDR and 10-bit output selection are automatic capability decisions. Compatible
HDR/10-bit input is preserved when the selected path supports it. `-sdr`
explicitly requests an SDR transcode. Remove `-hdr` and `-10bit` because they
duplicate automatic behavior. Support only `-deint` and `-maxbr`; reject the
`-deinterlace` and `-maxbitrate` aliases.

## Reason

One unambiguous control per policy reduces configuration combinations without
removing useful behavior. Automatic selection already expresses the normal HDR
and 10-bit case, and `-sdr` is the meaningful override.

## Alternatives considered

- Retain all historical spellings: rejected as unnecessary interface surface.
- Add negative HDR/10-bit controls: rejected because `-sdr` owns the required
  conversion policy.

## Consequences

The removed options fail with configuration status 64. Existing callers using
them must remove `-hdr`/`-10bit` and replace `-deinterlace`/`-maxbitrate` with
`-deint`/`-maxbr`.

---

# ADR-004: Preserve a modular data-safe runtime

## Status

Accepted

## Date

2026-08-29

## Decision

Keep a thin entry point and separate CLI, cache, hardware, probe, policy, and
common modules. Build FFmpeg commands with arrays and phase ownership, never
`eval`. Store capabilities in a validated, versioned, tab-delimited data format
that is parsed rather than sourced.

## Reason

This separates security-sensitive boundaries, supports Bash 3, makes behavior
testable without inherited helper structure, and prevents a writable cache from
becoming executable shell input.

## Consequences

Old shell-assignment caches are invalid and require `--recache-only`. The
wrapper owns input structure, hardware initialization, video encoding and
filters, and the MPEG-TS stdout destination.

---

# ADR-005: Use metadata-validated adaptive probing

## Status

Accepted

## Date

2026-08-29

## Decision

Probe with a fast 1-second/1-MB tier. Accept it only when the selected video and
audio metadata is complete. Retry incomplete metadata at 2 seconds/2 MB, then
use native FFprobe defaults if needed. Keep transport failures terminal instead
of expanding them. Use the winning limits for final FFmpeg startup, redact
source locations, and replay captured `pipe:0` bytes exactly.

## Reason

Fast probing materially reduces startup time for healthy live sources, while
metadata validation avoids accepting incomplete audio/program information.
Transport retry is a different concern and can amplify provider load or expose
credentials.

## Consequences

Probe outcomes are observable in diagnostics without revealing the source URL.
Finite stdin and live URLs have regression coverage.

---

# ADR-006: Schedule by verified concurrent capacity and weighted visible load

## Status

Accepted

## Date

2026-08-29

## Decision

Discover physical hardware independent of render-node numbering, test each
candidate/device combination, and define usable capacity with simultaneous real
transcodes that each maintain at least 1.2x speed. Use short boundary tests and
longer confirmation. Select the visible GPU with the lowest weighted
active-load/capacity ratio, breaking ties toward the primary. Weight a job by
the greater input/output pixel rate relative to 1080p30.

## Reason

Single-stream speed does not predict the useful difference between an Intel
integrated GPU and Arc A310 under concurrent IPTV load. Pixel-rate weighting
accounts for 720p, 1080p60, and scaling workloads without a required daemon.

## Consequences

Results are hardware- and environment-specific. Explicit device overrides
bypass selection. Only processes visible in the current PID namespace can be
counted; unknown work is conservative. Re-measure after relevant hardware,
driver, FFmpeg, container, or host changes.

---

# ADR-007: Normalize only when an active policy requires it

## Status

Accepted

## Date

2026-08-29

## Decision

Resolve output policy before building FFmpeg arguments and stream-copy video
whenever the input already satisfies every active requirement. Re-encode once
when any codec, resolution, bitrate, SDR, or deinterlace requirement differs,
and state each reason in credential-safe diagnostics.

Constraints are independent and optional:

- `-maxres` is a maximum height; never upscale.
- `-maxbr` is a guaranteed video ceiling. Unknown bitrate must transcode;
  constrained VBR targets the lower of the normal rate or 85% of the ceiling,
  with a buffer twice the ceiling.
- `-maxchan` is an audio maximum and never causes upmixing.
- `-sdr` tone-maps HDR input to BT.709 SDR.
- `-deint` affects only input identified as interlaced.

Automatic HDR/10-bit behavior follows ADR-003. Consumer profiles, not the
wrapper, own bundled defaults such as the 720p mobile policy.

## Reason

The project is a compatibility normalizer, not an always-transcode pipeline.
This minimizes generation loss, latency, startup work, and GPU consumption
while allowing strict profiles to compose several changes into one pipeline.

## Alternatives considered

- Always use the fastest encoder: rejected as unnecessary quality loss.
- Treat a maximum as a fixed target: rejected because it would upscale or
  upmix.
- Build a separate transcode per constraint: rejected because transformations
  can be combined safely.

## Consequences

Any new policy participates in the same mismatch decision. A change that makes
compatible video transcode requires explicit rationale and regression tests.
The unconstrained video rate remains 8 Mbps at 1920x1080 scaled by output pixel
count, with a 2 Mbps floor.

---

# ADR-008: Normalize audio independently and preserve compatible AAC

## Status

Accepted

## Date

2026-08-29

## Decision

Copy AAC when it satisfies the optional channel limit. Convert non-AAC audio to
AAC. Downmix only when the source exceeds `-maxchan`; never upmix. Use 96 kbps
mono, 192 kbps stereo, 384 kbps 5.1, 512 kbps 7.1, and 64 kbps per channel for
other layouts. Use asynchronous resampling for transcoded live audio. Emit no
audio options when no audio stream exists.

## Reason

Audio compatibility and video normalization are independent. Preserving
compatible AAC avoids loss and cost, while non-AAC inputs and explicit channel
ceilings still need deterministic normalization.

## Consequences

Video may copy while audio transcodes, or the reverse. Audio policy must never
force unrelated video work.

---

# ADR-009: Make capability state persistent, authoritative, and safely degradable

## Status

Accepted

## Date

2026-08-29

## Decision

Store runtime state under `FFMPEG_SMART_STATE_DIR` when supplied and never rely
on a replaceable installation directory for managed integrations. Cache active
selection by current hardware/software identity while retaining reusable
per-device measurements by physical signature across render-node swaps, host
moves with equivalent devices, or removal of a second GPU. An explicit recache
discards reusable measurements.

`--cache-status` is read-only and prints one of `valid`, `missing`, `invalid`,
`stale`, or `unavailable`. It succeeds only for `valid` and returns status 78
otherwise. `--recache-only` performs maintenance without requiring media input.

A live recache owns `.benchmark.lock`, identified by PID plus `/proc` start
time. Only the top-level owner outside a Bash subshell may remove it. Managed
integrations may set `FFMPEG_SMART_REQUIRE_CACHE=true` and opt into
`FFMPEG_SMART_CACHE_FALLBACK=proxy`. The degraded path performs stream copy to
MPEG-TS only; it does not approximate Smart policy or CPU transcode. A fallback
marker is a notification signal, not proof of capability state.

## Reason

Install updates, host changes, and long hardware scans must not produce stale
or executable state, false healthy status, lock races, or unexplained total
service loss.

## Alternatives considered

- Source cache assignments: rejected as executable untrusted state.
- Let consumers parse cache internals: rejected because validity belongs to the
  wrapper.
- CPU transcode during maintenance: rejected as unsafe host load and false
  policy emulation.
- PID-only lock identity: rejected because containers reuse PIDs.

## Consequences

Legacy caches require one rebuild. Degraded stream copy can still fail for an
input that MPEG-TS cannot carry. Integrations enabling fallback must notify the
operator and provide a recache path.

---

# ADR-010: Preserve typed mappings and phase ownership

## Status

Accepted

## Date

2026-08-29

## Decision

Represent every advanced FFmpeg argument as an array element within input,
mapping, video, audio, or mux scope. Each scope supports inherit/add/replace;
mapping also supports all. Reject structural options owned by the wrapper.
Never parse a shell command string or use `eval`.

Require exactly one normalized video. When subtitle, data, or attachment
streams are mapped, explicitly copy them with `-c:s copy`, `-c:d copy`, and
`-c:t copy`. FFmpeg remains authoritative for whether an auxiliary codec can be
muxed into MPEG-TS.

## Reason

FFmpeg options are position-sensitive, and a single free-form field can move
input flags to output scope, override hardware policy, inject shell syntax, or
replace the fixed stdout destination. Explicit auxiliary copy avoids FFmpeg
selecting an unavailable MPEG-TS encoder.

## Consequences

Every consumer must pass one option token per field/value. The wrapper retains
ownership of input structure, hardware devices, video encoder/filter graph,
and `-f mpegts pipe:1`. Incompatible mapped streams fail with a native,
attributable FFmpeg error.

---

# ADR-011: Keep this repository canonical and downstream copies immutable

## Status

Accepted

## Date

2026-08-29

## Decision

`matrix2669/ffmpeg-adaptive` is canonical for the runtime. A Dispatcharr plugin
or other consumer may bundle a reviewed copy only when it records the source
repository, immutable commit, path, and checksum and provides a reviewable
check/sync process. Source changes never silently modify an existing tag,
plugin archive, registry entry, or installation.

## Reason

The related plugin must be installable without network access, but duplicated
source drifts unless exact identity and synchronization are explicit.

## Consequences

Moving from the prior fork to this repository requires a separate plugin pin,
checksum, test, tag/registry, installation, and deployment decision. Repository
bootstrap authorizes none of those promotions.

---

# ADR-012: Use semantic versions and immutable publication gates

## Status

Accepted

## Date

2026-08-29

## Decision

Use the workspace standalone `feature/fix -> dev -> main` lifecycle. `VERSION`
and the entry-point version are the canonical project version. Beta tags are
immutable `vMAJOR.MINOR.PATCH-beta.N` refs on tested `dev` commits; stable tags
are immutable `vMAJOR.MINOR.PATCH` refs on `main`. A release requires the
behavior, hardware/integration, provenance, ownership, archive-content, and
checksum gates in `RELEASE.md`.

## Reason

Human-readable versions identify compatibility while immutable commits and
checksums identify exact source. Licensing confidence and a passing unit suite
do not replace real hardware/integration validation.

## Consequences

The initial `0.1.0` repository state is not a tag or Release. Tags, GitHub
Releases, downstream pins, registry publication, and deployment remain
separate explicit actions.

---

# ADR-013: Bind measured capacity to the production hardware path

## Status

Accepted

## Date

2026-08-30

## Decision

Build QSV and VAAPI benchmark input arguments with the same hardware-decoder
constructor used by normal transcodes. Keep the representative Main10 fixture
and perform any required pixel-format conversion on hardware frames. A cached
device capacity is eligible for automatic scheduling only when its measured
accelerator and codec match the requested runtime path. Prefer exact matching
device rows. If no exact row exists, preserve explicit accelerator/codec
requests but schedule them at a conservative capacity of one. After selection,
use that device row's low-power and 10-bit-encode capabilities rather than the
global best-device values; use conservative defaults for an unmatched path.
On multi-GPU hosts, choose the global path from discovery, rebenchmark every
compatible secondary device on that same accelerator/codec, and only then
measure per-device capacity. Retain an independent best path only when the
device cannot run the selected common path.

Advance the capacity-policy fingerprint whenever command or acceptance policy
changes, even if the serialized cache format does not change. Bound each
concurrent level by wall time as well as media duration; terminate all jobs and
reject the level if that deadline expires. Grow unbounded capacity probes by
50% per step rather than doubling them, then use the same binary search and
confirmation policy after finding an unstable upper bound.

## Reason

The earlier benchmark initialized an encoder device but decoded the fixture in
software before uploading frames. Production transcodes hardware-decode on the
selected device. That made the measured capacity a different workload and
allowed the primary device's low-power choice to be applied to a secondary
device measured under another mode.

## Alternatives considered

- Retain software decode as an encoder-only capacity test: rejected because it
  cannot represent end-to-end live-transcode contention.
- Apply the globally fastest path to every device: rejected because per-device
  capacity is only meaningful for the path that produced it.
- Add accelerator/codec-specific capacities for every device: deferred; one
  measured best path per device remains sufficient while runtime eligibility
  enforces identity.

## Consequences

Policy-2 caches are stale and require one rebuild. Reported totals may be lower
than encoder-only measurements because decoding now consumes the same hardware
resources as production. A requested path that differs from every best
per-device row remains available, but it schedules with capacity one and
conservative encoder capabilities until the cache format can represent a full
per-path capacity matrix. Deliberately unstable upper-bound probes can no
longer hold a cache rebuild open indefinitely.

---

# ADR-014: Treat benchmark diagnostic persistence as benchmark integrity

## Status

Accepted

## Date

2026-09-07

## Decision

Run each hardware benchmark in a fresh private diagnostics directory. A failed
diagnostic-file creation is a benchmark failure (status 73), never evidence that
a hardware path is unavailable. Only after a successful capability-cache write,
publish one consolidated `benchmark-latest.log` and remove older per-worker
candidate, capacity, and 10-bit logs. Failed runs retain their private evidence.

## Reason

Root-owned historical worker logs made a `dispatch`-owned rebuild unable to
write hardware diagnostics. The old code treated each failed candidate as an
ordinary unsupported path, then successfully saved a software-only cache.

## Consequences

A state-directory ownership error is visible and repairable rather than silently
causing CPU encoding. The retained latest log is diagnostic-only and not part of
cache validity or runtime selection.

## Beta-4 integrity clarifications

The status-73 boundary applies through candidate tests, 10-bit probes, capacity
levels, and the cache rebuild caller. Unsupported codecs or unavailable paths
remain ordinary rejection (status 1); inability to create, read, or persist a
diagnostic is never converted into that rejection. Benchmark stderr is persisted
through a checked writer process so failures after initial file creation are
also status 73.

Cache replacement is checked before summary publication. A failed cache write
leaves the prior usable cache and prior summary/evidence untouched. Summary
publication writes and validates a private temporary file, atomically moves it
into the regular `benchmark-latest.log` destination, and only then removes old
worker logs and failed-run directories. Every generated log receives a unique
per-run suffix, and cleanup refuses paths outside the state directory. Capacity
workers receive TERM followed by bounded KILL cleanup when setup fails, so an
early diagnostic failure cannot orphan workers or watchdogs.

These clarifications preserve ADR-014's ownership and retention decision while
making its transaction and failure boundaries explicit. Revisit if the cache
format becomes transactional across cache and diagnostics or if benchmark
execution moves to a managed supervisor.

Decision closure on 2026-09-21 confirms the operator's existing requirements:
retain only the newest successful consolidated diagnostic, fail I/O errors
instead of treating them as hardware rejection, and preserve diagnostic
evidence on failure. Cache and summary are not a two-file atomic transaction:
summary or cleanup failure after cache replacement still returns failure.
The Dispatcharr integration must report that process outcome independently of
whether the current cache validates. No benchmark thresholds or hardware
selection policy change. Capacity cleanup gives the owning worker a two-second
TERM grace before child KILL, with a three-second outer worker grace; review
these bounds if orchestration or child ownership changes.

Internal capacity measurements must keep their numeric result in the existing
global result variable while suppressing probe stdout at the rebuild boundary.
The wrapper's stdout is the media MPEG-TS boundary, so a successful multi-device
rebuild must never prepend capacity numbers to a stream.

The shared lock distinguishes caller roles: streaming admission treats a fresh
`starting` placeholder as active maintenance and retains it, while benchmark
acquisition continues to treat that placeholder as consumable and replaces it
with its numeric PID/start-time owner. Numeric live owners remain blocking for
both callers, and expired placeholders are removed.

---

# ADR-015: Pin the CI shell checker and separate release-source validation

## Status

Accepted for the pending CI-only replacement

## Date

2026-09-21

## Decision

CI installs the official ShellCheck 0.11.0 Linux x86_64 release asset from its
fixed GitHub release URL, verifies SHA-256
`8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198`, prints the
tool version, and runs the complete validation suite. The workflow reports its
workflow commit separately from the immutable beta.4 source commit
`913a958fd5f9edc231c49a70539a09f611fdcc5a`, validates both, and confirms the
tracked checkout remains unchanged.

## Reason

GitHub runs `35631984969` and `35631983498` failed because runner-provided
ShellCheck 0.9 emitted SC2218 false positives. ShellCheck 0.11.0 contains the
upstream accuracy fix. The exact beta.4 source must remain independently
auditable while the workflow definition changes.

## Consequences

The CI checker is deterministic and checksum-pinned, and a workflow follow-up
cannot be mistaken for a runtime or release-source change. The CI replacement
remains pending until its own workflow commit passes review; no runtime,
version, tag, or publication state changes here.
