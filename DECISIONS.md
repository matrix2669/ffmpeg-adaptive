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


## Automatic codec clarification — 2026-10-29

The operator requested correction of unnecessary H.264-to-HEVC conversion when
Smart's cache preferred HEVC and only `-deint` was active on progressive input.
Without `-vc`, H.264 and HEVC satisfy the codec compatibility requirement. The
cached `best_codec` is an encoder preference for required conversions, not a
reason to transcode otherwise compatible video. Other input codecs, including
unknown codec names reaching policy resolution, still require normalization to
the cached codec (H.264 fallback). This retains the existing compatibility set;
it does not broaden copying to every codec MPEG-TS might carry. Probe admission
for missing metadata remains unchanged.

An explicit `-vc` requires that codec and overrides the cached preference for
any conversion. Resolution, bitrate (including unknown bitrate under `-maxbr`),
HDR-to-SDR and interlace constraints remain independent conversion reasons. If
one requires conversion in automatic mode, use the cached preferred encoder;
do not constrain that conversion to the input codec. Accelerator selection alone
is not a conversion reason. Compatible HDR/10-bit video can copy without encoder
capability checks because no encoder is used. Audio conversion never forces
video conversion (ADR-008).

This clarifies ADR-007 rather than changing its copy-first intent. Rejected:
letting benchmark preference force every stream to its codec, or copying all
unknown codecs without normalization. Regression coverage must exercise both
cached codec preferences, explicit codec overrides, active/satisfied limits,
progressive/interlaced input, HDR and independent audio decisions. Revisit the
compatibility set only with an explicit supported-codec policy change.

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

Accepted; CI replacement passed

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

The CI checker is deterministic and checksum-pinned, and CI run
`35633440274` passed workflow definition `10a6e4b8e16b66857df3b03a7bb6d0bb88fc9929`
against unchanged source `913a958fd5f9edc231c49a70539a09f611fdcc5a`. The
managed beta.5 benchmark subsequently completed at
`2026-09-21T17:51:16.719376+00:00` with return code 0, valid cache, no lock,
and reviewed cleanup. Native capacity and bounded pipe evidence are recorded
separately; no live-provider channel was fetched and no actual profile was
created.

---

# ADR-016: Separate the authorized branch promotion from stable publication

## Status and date

Accepted for the 2026-10-20 branch promotion only.

## Decision and authority

The operator requested promotion of `ffmpeg-adaptive` from `dev` to `main` on
2026-10-20. Promote the reviewed `dev` history based on
`a818fee172dde2d0cf39dcd43d1c52491dbfc82b`, plus this scoped documentation,
using ordinary non-force fast-forwards through `dev` to `main` after checks.
Do not convert this request into a stable release or downstream update.

## Rationale and consequences

The runtime and tests are unchanged from tested beta.4 source
`913a958fd5f9edc231c49a70539a09f611fdcc5a`; the plugin still pins that exact
commit. Preserve `0.1.0-beta.4` in all version sources, avoiding a version-only
runtime change and any downstream cache implications. Branch promotion does
not certify a new stable artifact. `RELEASE.md` continues to govern a later
stable version, immutable tag, fresh provenance audit, package/checksum and
explicitly approved GitHub Release. No tag, Release, registry, plugin pin,
installation or deployment is part of this promotion.

## Closure and review trigger

The scope answers the material choices: exact existing code, branch promotion
only, unchanged beta identity, and separate publication. No accepted behavior,
license or release rule is superseded. Revisit when the operator requests a
stable release or a downstream pin update. Record dev/main CI terminal results
in the promotion report; do not claim completion on pending or failed CI.

---

# ADR-017: Complete the approved 0.1.0 stable release

## Status and date

Accepted, 2026-10-20; extends the prior branch-only ADR-016 after new approval.

## Decision

The operator subsequently approved finishing the promotion and release. Finalize
0.1.0 in VERSION, ffmpeg-smart.sh and benchmark-accel.sh; promote through dev to
main, publish immutable v0.1.0 and a normal GitHub Release with an inspected
`ffmpeg-adaptive-v0.1.0.tar.gz` and SHA-256 file. Preserve old tags and artifacts.

## Rationale and boundaries

The accepted beta.4 runtime behavior, modules, tests and hardware evidence remain
unchanged; only version identification and release records change. Repeat the
full offline suite and provenance audit. This approval supersedes ADR-016's
publication exclusion for this exact release only. It does not authorize live
hardware work or deployment. The Dispatcharr plugin continues to vendor
913a958fd5f9edc231c49a70539a09f611fdcc5a, avoiding any cache-fingerprint change
in its installed runtime. A stable standalone release is not a command to
rebundle downstream code. Further runtime changes require their own test cycle.

## Closure

Exact version, artifact format, pin independence, licensing and publication
scope are explicit; no runtime behavior or license decision is changed. CI and
asset verification results belong in the release report and release notes.

---

# ADR-018: Share one HTTP MPEG-TS startup reader across probe and playback

## Status and date

Accepted experimental interface, 2026-10-30. Production rollout, performance
acceptance and downstream default selection require separate validation.

## Problem and decision

Independent fast, expanded and default URL probes followed by playback can open
several provider sessions and discard their startup media. Opt-in
`--shared-input` or `FFMPEG_SMART_SHARED_INPUT=true` runs one Python stdlib HTTP(S)
reader. Every metadata tier starts at byte zero of the same RAM-retained input;
final FFmpeg receives that exact prefix and the continuation without gaps.
The first 377 bytes must contain sync bytes at offsets 0, 188 and 376. This
interface supports continuous 188-byte MPEG-TS only. No fixed prefill timer is
introduced. Python 3.9+ is required only when enabled.

The standalone default is false. `--shared-input-auto` or environment value
`auto` is a compatibility selector: use shared input only for HTTP(S) path suffix
`.ts` or query keys `format`/`output` with values `ts`/`mpegts`, case-insensitive,
excluding `.m3u8` paths. Any advanced input-option token or missing Python keeps
legacy handling. This checks URL hints only; it never acquires a body to decide.
A hinted non-TS response fails without fallback. This makes a mixed-source
profile possible without treating every HTTP response as MPEG-TS. Unhinted
known TS sources require explicit opt-in. The helper owns a random-token
loopback HTTP broker and a process group containing the existing wrapper, probes and final
FFmpeg. Source URLs, credentials and broker tokens never enter telemetry.
Broker probe routes replay without freeing bytes; its sole playback route frees
chunks after writing them to FFmpeg. Queue saturation blocks upstream reading.
No media is dropped, spooled to disk or reacquired. Input EOF after validated TS
can be a normal finite fixture; premature Content-Length EOF, socket failure,
unsupported format and timeout fail the session. There is no legacy fallback
after acquisition. Existing copy/transcode, explicit codec, audio, hardware,
cache and opt-in degraded-proxy policy remains owned by the existing modules.
A degraded proxy uses the same broker when shared input was requested.

## Defaults, bounds and transport contract

- `FFMPEG_SMART_SHARED_INPUT_BYTES`: 16777216 retained payload bytes (16 MiB),
  allowed 65536..1073741824. This bounds queue payload, not total process RSS or
  OS socket/pipe buffers. Reader, per-client and output forwarding chunks are
  at most 65536 bytes each, with at most a 376-byte validation prefix. Short
  reads coalesce into chunks immediately, bounding per-chunk object overhead
  without waiting for a full chunk.
- `FFMPEG_SMART_SHARED_INPUT_DEADLINE`: 20 seconds from supervisor start to
  first successful stdout media write; allowed 1..300. Probe starvation at a
  small cap fails at this deadline rather than reopening the source.
- `FFMPEG_SMART_SHARED_INPUT_IDLE`: 30 seconds per blocking network operation,
  allowed 1..300. Cancellation shuts down the owned upstream socket, terminates
  the child process group, gives it 0.5 seconds, then kills remaining members.
- At most five redirects precede the single accepted status-200 media body.
  Cross-origin redirects strip URL Basic Authorization. Redirect credentials
  and HTTPS-to-HTTP downgrades are rejected. `upstream_opens` counts accepted
  media bodies (zero or one); `upstream_requests` counts HTTP handshakes including
  redirects. No HTTP error retry, body reconnect or restart occurs.
- The dedicated user-agent and URL Basic authentication are supported. All
  advanced input-option tokens are rejected before acquisition. This prevents
  silently dropping cookies, headers, proxy, authentication, format or timeout
  settings whose FFmpeg semantics the helper does not implement. Python uses
  direct HTTP connections and system TLS trust; it does not inherit FFmpeg's
  protocol implementation or environment proxy behavior. Compressed HTTP bodies
  are rejected. Other phase options and input add/replace mode still apply to
  FFmpeg's local broker input.
- Explicitly enabling the option for HLS, non-TS HTTP, other protocols, files
  or stdin fails clearly. Without opt-in, their existing paths remain intact.

## Rationale, alternatives and scope

A supervisor with a private broker preserves existing adaptive metadata parsing
and codec policy while owning cleanup independently of shell exec/pipelines.
Independent provider requests waste media and cannot guarantee continuity.
A disk spool violates the RAM requirement. Remuxing upstream through a separate
FFmpeg reader would change the original byte stream. A fixed prefill delays
startup and does not ensure useful metadata. HLS acquisition, ongoing media-time
reservoir management and downstream playback buffering are separate work.
The existing downstream bridge reservoir is unchanged.

## Evidence, closure and review triggers

The operator requested shared probe/playback acquisition, fast startup and an
explicitly bounded initial TS implementation on 2026-10-30. Scope, opt-in
compatibility, no silent option loss, no reopen, privacy and cleanup choices
close the interface for local implementation. Defaults are conservative
experimental choices; tune only after measured startup/output and memory data
on representative streams. Telemetry records first source byte, per-tier broker
request starts, first playback feed, first stdout media, peak retained payload
and request/session counts; it is wall-clock startup evidence, not a retained
media-duration claim. The source helper must be included in any immutable
runtime package and downstream per-file checksum manifest. A source checkpoint
is not a downstream pin, installation, default-profile change or release.

Required local tests cover exact prefix replay through all tiers and playback,
one direct-source request, redirect auth boundaries, bounded backpressure,
EOF/read failures, cancellation, concurrent isolation, credential-safe output,
real audio/video decode and unchanged policy regressions. Live provider,
hardware and production performance evidence are separate gates. Review this
ADR before supporting arbitrary input options, HLS, proxy behavior, retry,
additional TS packet sizes, non-POSIX platforms or default enablement.

---

# ADR-019: Configure video-copy compatibility separately from conversion preference

## Status, date and authority

Accepted, 2026-10-30. The operator requested configurable receiver compatibility
while explicitly retaining the script and plugin as universal products. Extends
ADR-007 with general policy controls; existing defaults remain unchanged.

## Decision

`--copy-codecs LIST` is a nonempty comma-separated list of FFprobe video codec
names, restricted to lowercase ASCII letters, digits and underscores per name,
without spaces or empty elements. CLI values are lowercased. The default is
`h264,hevc`. Listed source codecs are eligible for automatic copy only when all
other active video constraints are satisfied. Listing a codec does not guarantee
that a receiver or MPEG-TS supports it; FFmpeg remains the mux authority.

`--fallback-codec h264|hevc` optionally selects the conversion codec, independently
of that copy set. Omission retains the cached preference (H.264 if absent).
Unsupported/unknown codecs outside the copy set require conversion. Any required
resolution, bitrate, deinterlace or SDR conversion targets the explicit fallback
when provided, regardless of cached codec preference. For example,
`--copy-codecs h264,mpeg2video --fallback-codec h264` preserves compatible H.264
and MPEG-2 while converting HEVC or deinterlaced/resized MPEG-2 to H.264.

Explicit `-vc h264|hevc` takes priority over both list membership and fallback:
require that exact codec and use it when another constraint requires conversion.
Thus MPEG-2 plus explicit `-vc h264` converts even if MPEG-2 is listed, and HEVC
plus explicit `-vc hevc` can copy even if HEVC is not listed. This deliberate
operator override preserves the existing codec contract. Audio stays independent.
These options govern video codec membership, not HDR, profile/level, audio or
universal receiver capabilities. No receiver-specific mode is introduced.

## Rationale and alternatives

Copy eligibility describes receiver/container compatibility; cached encoder
preference describes measured performance. Separate controls let each deployment
express its accepted codec set and fallback without changing other users.
Receiver-specific named presets would make a universal tool depend on one
system. Always forcing one codec would discard otherwise compatible inputs.
Ignoring explicit `-vc` would break an accepted user contract. Inferring copy
eligibility from benchmark preference would repeat the earlier ownership error.

## Consequences, evidence and review

No hardware selection/capacity, cache schema/fingerprint/version, audio policy,
shared-input transport, mux or output destination changes. Canonical source
remains the sole behavior owner. Plugin integration may expose general per-Stream
copy-list and fallback fields with unchanged defaults. The operator may select
H.264/MPEG-2 plus H.264 fallback for a local profile during separately authorized
deployment. Output Profiles stay unchanged unless explicit options request it.

Tests cover both cached codec preferences, configured H.264/MPEG-2 copy,
unsupported HEVC conversion, MPEG-2 deinterlace conversion, resolution/bitrate/
SDR conversion, independent list/fallback choices, validation and explicit codec
precedence. Existing standard tests continue to pass. Live receiver evidence is
a separate acceptance step. Review defaults or allowed fallback encoders only
with new compatibility requirements and canonical encoder support. Decision
closure resolves defaults, syntax, precedence, scope and ownership; no profile,
default, installation or publication change is inferred.


## ADR-018 review clarification: private broker proxy isolation (2026-10-30)

The owned wrapper/FFprobe/FFmpeg child environment removes inherited HTTP,
HTTPS, ALL, FTP, SOCKS and bypass proxy variables case-insensitively, then sets
both `no_proxy` and `NO_PROXY` to `127.0.0.1,localhost,::1`. These children use
the private token-bearing loopback broker; forwarding that URL through an
ambient proxy would disclose its token and break replay before upstream opens.
Only the owned child environment changes. The helper's upstream HTTP client
remains explicitly direct, and unselected legacy acquisition retains its
existing environment/transport semantics. A local recording-proxy regression
starts without any `no_proxy`, sets both cases of the protocol proxy variables,
and requires all-tier replay, exact playback bytes, one upstream request and
zero proxy requests or token-bearing diagnostics.

---

# ADR-020: Resolve preferred-copy policy dynamically and preserve proxy transport in Auto

## Status and authority

Accepted, 2026-10-30, for the beta.3 simplification requested by the operator.
Extends ADR-019 and the Auto eligibility contract in ADR-018; standalone defaults
and explicit shared-input Off/Strict behavior remain unchanged.

## Copy selection

`--copy-codecs preferred` is exclusive: it cannot be combined with named codecs.
After normal cache admission, it uses the cache's current `h264` or `hevc`
preference as the sole automatic-copy codec. A missing/invalid cache retains the
existing required-cache failure or opt-in degraded-copy contract. An unsupported
cache preference cannot become an arbitrary copy target; preferred policy fails
with status 78. Explicit `-vc` still takes priority over the copy selection, and
processing limits still require conversion. Conversion normally uses the cached
encoder; the existing standalone `--fallback-codec` expert option remains valid.

Named lists accept `mpeg2` as a public alias for FFprobe's `mpeg2video`; the old
name remains supported. Trim surrounding/token whitespace and normalize case,
rejecting empty tokens, malformed names and mixed preferred/named selections
before acquisition. Standalone default remains `h264,hevc`. A plugin may map a
blank text field to `preferred` without treating a missing value as a fixed codec.

## Conservative automatic input

Auto retains legacy acquisition whenever any nonempty HTTP, HTTPS, ALL, FTP or
SOCKS proxy variable is present, case-insensitively, even if no_proxy appears to
bypass the source. Direct helper HTTP semantics cannot prove equivalence to an
ambient FFmpeg proxy configuration. Custom input options, HLS/opaque URL hints,
unsupported protocols and unavailable Python retain their previous Auto gates.
No body is opened to decide eligibility; proxy values and source URLs are not
logged. Strict shared input remains an explicit direct-HTTP opt-in, and private
broker clients keep their scoped proxy isolation.

## Timing and cancellation boundary

No standalone timeout default changes. The plugin may fix 64 MiB retained
payload, a 10-second first-output watchdog and an independent 30-second network-
operation guard. These are not injected Dispatcharr settings. Official 0.33.0
may switch at its 8-second startup-no-data clock when alternatives exist, and
disables that short clock when exhausted; the wrapper watchdog is still useful.
The existing TERM/INT/HUP path shuts down the reader socket and terminates the
owned worker process group with a 0.5-second grace. Local bounded tests cancel
both probing and playback before the 10/30-second guards and require exit with
no live workers within three seconds. This is worker-fixture evidence, not a
claim that every parent/client/live-provider failure path has been proven.

## Closure and review

Defaults, aliases, precedence, failure semantics and proxy ownership are explicit.
Tests cover both cache preferences, filters and explicit codecs, malformed/mixed
lists, missing/invalid cache admission, case-insensitive proxy gating, exact media
replay and bounded cancellation. No hardware/audio/cache-format, live operation,
installation or publication change is inferred. Review Auto gates only with
transport-equivalence evidence; do not trade legacy proxy behavior for automatic
optimization based on a URL suffix alone.

---

# ADR-021: Classify unhinted HTTP input using the retained response

## Status, authority and supersession

Accepted for implementation on 2026-10-30. The operator requested shared input
for continuous TS sources whose URLs contain no TS hint after channel 588 used
legacy probing. This supersedes ADR-018/020's URL-hint-only Auto gate and
no-fallback-before-format-detection wording. Strict and Off remain unchanged.

## Decision

Auto admits direct HTTP(S) with Python 3.9+, no custom input-option tokens, and
no ambient HTTP/HTTPS/ALL/FTP/SOCKS proxy variables. Known `.m3u8` paths continue
to bypass classification. The owned upstream reader starts after cache admission
and checks its actual initial body for 188-byte TS sync at offsets 0, 188, 376.
MIME is advisory only. Valid TS bytes, including byte zero, remain in the same
RAM queue for all probe tiers and playback; classification adds no second GET
or upstream media open, no fixed prefill, and no stream rewrite.

Before launching any probe/playback child, non-TS bodies, short unsupported
bodies and unsupported content encoding select a one-time legacy fallback.
Close the classification connection, preserve the original URL/environment, and
run the ordinary wrapper under the same supervisor startup deadline and owned
process-group cleanup. FFmpeg remains responsible for opaque HLS, redirects,
relative playlist URIs and authentication. The internal `FFSMART_SHARED_LEGACY`
child marker disables only Auto classification and avoids repeating an explicit
cache rebuild; it cannot turn strict mode into fallback. No provider URLs,
credentials or broker tokens enter the new logs.

A fallback may reopen non-TS via the existing legacy probe/playback behavior.
It is not a successful single-connection optimization. Emit `auto_fallback=non-ts`
and label its summary `shared-input classification`; those counters cover only
the classifier and must not be treated as total legacy acquisitions. Successful
shared TS retains the existing telemetry contract.

Network/HTTP-status, unsafe redirect, truncated-body, cap starvation and startup
timeout failures remain terminal; they never retry the source or fall back.
After valid TS is selected, format/read failure also remains terminal. Retained
payload bounds, independent idle guard, explicit cancellation and no-disk-spool
policy are unchanged. Legacy fallback keeps normal proxy behavior (though Auto
bypasses configured proxies before opening) and receives no private broker URL.

## Alternatives and consequences

A separate MIME/HEAD/probe GET would discard startup data and can open a second
provider session. Trusting Content-Type fails for generic or incorrect server
labels. Feeding an HLS playlist through the broker changes relative URI/auth
resolution; fallback must use the original URL. Supporting an HLS shared reader
is a separate design, not an implicit consequence of this change.

The one extra classification request for previously opaque non-TS sources is an
explicit compatibility cost. Known HLS keeps its zero-classification path.
Provider-specific redirects, cookies or signed one-use URLs may need custom
input configuration and therefore the existing Auto bypass. No general HTTP
transport-equivalence guarantee is made.

## Evidence and review triggers

Local regression requirements: missing/misleading MIME and opaque TS preserve
all-tier prefix replay and one media request; strict unsupported input remains
fail-closed; opaque HLS works through a real redirect, Basic authentication and
relative segment URL with decoded audio/video; non-TS fallback runs once before
probes; errors do not retry; startup deadline and cancellation cover classifier
and legacy child. Run the complete validation suite and independent review,
then separately measure live startup. Source work does not install a plugin or
change profiles, channels, defaults, tags or registries. Review this decision
before adding shared HLS, cookies, additional packet sizes or retry behavior.

### Authenticated relative redirect correction

The real opaque-HLS fixture exposed an inherited userinfo bug: `urljoin` kept
credentials from the original URL in a relative target, which the redirect guard
then rejected as newly supplied credentials. The internal transport URL now
removes initial userinfo after constructing the scoped Basic header. Relative
redirects retain same-origin auth; explicit userinfo in Location is still rejected
and cross-origin headers remain stripped. No authentication capability is added.

Local completion: `./scripts/validate.sh` passed with Python 3.14.7, FFmpeg 9.0.1
and ShellCheck 0.11.0 on 2026-10-30; all 20 shared-input methods passed. Local
loopback fixture permission was required. No source provider, installed plugin,
profile or cache was changed by this implementation batch. Exact CI, independent
review and live startup evidence remain parent-owned gates.

---

# ADR-022: Close the accepted implementation through development integration

## Status, date and authority

Accepted, 2026-11-02. The owner requested completion of development integration
for the feature changes already packaged by the plugin. This extends ADR-012's
feature/fix-to-dev workflow; it does not authorize the later main/release stages.

## Decision and rationale

Integrate the complete dependent chain from stable dev baseline
`5ed306892edfb27f25736eaf938edbd94ff5a8c0` through conditional-video
`81d811625e51e97c76f285267dc9c8d8ec885754`, shared-input/preferred-policy
`137103b0b5d2ed2f21976c65be2cd5bc816dbdb6`, and opaque-TS fix
`bb834684eb2c513e832c43ba6dbc773d5af10cbc`, together with the reviewed delivery
documentation. Packaging an immutable feature commit downstream is valid under
ADR-011, but does not move the canonical dev branch. The canonical integration
must therefore be completed and verified separately.

This explicitly supersedes the initial no-promotion exclusions in those three
branch records only for this dev integration. It leaves ADR-007 and ADR-018–021
behavior intact: standalone shared input remains off by default, copy defaults
remain `h264,hevc`, explicit codec precedence and independent audio remain,
and the plugin owns its distinct preferred-copy/Auto policy. No receiver preset,
cache schema/fingerprint change or runtime version change is introduced.

Reconcile current workspace standards at this integration boundary. Replace the
older per-task reconciliation guidance with the authoritative lifecycle;
preserve approval continuity, exact-SHA validation and one durable workspace
closeout. These delivery changes do not alter licensing, provenance, dependency,
behavior or release contracts. No standards exception is requested.

## Validation and consequences

Full mandatory CI must pass on the exact documentation successor before an
ordinary non-force fast-forward of dev. Original runtime CI/review is retained
as implementation evidence and cannot certify a different candidate SHA.
Record the actual accepted commit and remote dev head at closeout. Keeping the
accepted chain indefinitely on feature branches was rejected because it leaves
the integration branch behind downstream packaged development work.

Main promotion, version changes, tags, Releases, registry updates, downstream
source-pin changes, installation, profiles/defaults, provider operations and
branch deletion are excluded. Existing published tags/archives and their source
metadata remain immutable. Revisit only on a later explicit release/promotion
or operational request; integration evidence lives in the validation report.
