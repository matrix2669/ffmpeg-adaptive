# Agent Guidance

## Local Add-to-Defaults composition correction, 2026-11-13

The owner reports installed beta.5 rejected the actual safe chain
`aresample=async=1,dynaudnorm=f=150:g=15`, silently omitting required AAC
layout correction. Repair composition for supported layout-preserving chains,
retain order/explicit resampling and operator choices, preserve copy and Replace
semantics, avoid duplicate encoding, and diagnose unsupported/unsafe graphs
clearly. Test actual argv and realistic late joins. Prepare downstream plugin
and registry candidates locally; no publication or deployment is authorized.
This supersedes silent skip behavior where the new acceptance requires clear
unsupported-graph handling. Do not edit bridge/FIFO or live settings.

## Local AAC late-join source repair, 2026-11-13

The owner authorizes local evaluation/repair of Smart's automatic AC3 5.1(side)
to AAC path after channel505 diagnostics and a matching full-stream/late-join
reproduction. ADTS configuration zero requires a PCE that the current FFmpeg muxer
emits once. Evaluate conditional one-to-one side-to-canonical5.1 surround routing
only for known5.1(side) streams actually encoded to AAC. Preserve channel count,
sample rate, bitrate policy, existing resampling/normalization intent, explicit
operator codec/replace choices, stereo/mono and unrelated streams. Record the
intentional surround-label convention; do not claim the metadata layout name is
unchanged. Do not introduce an FFmpeg fork/PCE injector or edit the downstream
vendored runtime independently. No settings, live profiles, bridge/FIFO or other
channels may change. Work locally with tests and independent review; publication,
plugin pin/version updates and deployment require fresh approval.


## Purpose

`ffmpeg-adaptive` is the standalone matrix2669 source for an adaptive live
stream normalizer implemented in Bash. It owns its full source, documentation,
tests, licensing, branches, and release lifecycle.

The command remains `ffmpeg-smart.sh` for compatibility with existing
Dispatcharr profile definitions. A downstream integration must pin an immutable
commit and checksum; changes here never silently alter an installed plugin.

## Workspace Standards Reconciliation Gate

Ordinary established standalone work uses the pinned local guidance and applied
`WORKSPACE-STANDARDS.yaml`. Refresh and reconcile authoritative workspace
`AI-INSTRUCTIONS.md` and `AGENT-STANDARD.md` at bootstrap, explicit standards
work, and before integration into `dev`/`main` or release publication.

1. Locate the maintained `matrix2669/workspace` checkout with readable standards
   and Git history; run `<workspace>/scripts/reconcile-standards --check .`.
2. When the manifest is missing, pending, malformed or stale, stop that boundary
   and inspect `--diff` against this complete file, relevant decisions,
   code/configuration contracts, dependencies, branch/release policy and related
   projects. Established work uses relevant recorded history; bootstrap retains
   its complete evidence-backed history gate.
3. For unresolved authority, ask focused questions; record explicit
   contradiction resolutions in `DECISIONS.md` and realign affected artifacts.
   Only then run `--apply --confirm-reviewed-no-conflicts .`.

Missing authoritative standards/history or unresolved contradictions block the
required boundary. This lifecycle supersedes the former per-task gate, without
waiving validation, release or approval rules. An exception still needs explicit
owner approval and a dedicated section here stating scope, rationale, authority,
date and removal trigger. Preserve unchanged explicit approval across delegation.

Mandatory CI belongs to the exact candidate SHA. Documentation reconciliation
creates a new candidate requiring full validation; prior runtime CI alone is
insufficient. Reuse an original complete successful execution only for that
same SHA and required acceptance inputs, preserving run/job/artifact provenance.
Publish task-related workspace status once at durable logical closeout, rather
than after every intermediate push. Code-repository documentation follows its
owning branch; workspace documentation approval never promotes this source.

## Architecture

- `ffmpeg-smart.sh` is the thin compatibility entry point.
- `lib/ffsmart-cli.sh` parses and validates policy and phase-scoped FFmpeg
  arguments.
- `lib/ffsmart-cache.sh` owns the strict data-only cache schema and validity.
- `lib/ffsmart-hardware.sh` discovers devices, tests candidates, measures
  concurrent capacity, and selects visible GPUs.
- `lib/ffsmart-probe.sh` handles URL and non-seekable input probing, adaptive
  metadata tiers, prefix replay, and credential-safe diagnostics.
- `lib/ffsmart-shared-input.py` supervises the opt-in HTTP MPEG-TS RAM reader,
  private probe/playback broker and bounded owned process cleanup (ADR-018/021).
  Auto classifies the retained HTTP body; non-TS compatibility fallback uses the
  original URL before probes/output, while validated TS never reopens upstream.
- `lib/ffsmart-policy.sh` makes independent video/audio decisions and builds the
  final FFmpeg command.
- `benchmark-accel.sh` and `benchmark-live.sh` are operator-facing validation
  tools.

Runtime state does not belong in source control. Replaceable installations set
`FFMPEG_SMART_STATE_DIR` to a persistent writable location.

## Non-negotiable behavior

- Preserve explicit `DRI_DEVICE`, `QSV_DEVICE`, and `VAAPI_DEVICE` overrides.
- Keep HDR and 10-bit selection automatic. `-sdr` is the explicit conversion
  request; do not restore redundant `-hdr` or `-10bit` controls.
- Keep `-deint` and `-maxbr` as the only supported spellings; do not restore
  `-deinterlace` or `-maxbitrate` aliases without an accepted decision.
- Read workload markers only from visible `/proc/<pid>/environ` processes and
  count unknown FFmpeg work conservatively.
- Validate capacity with simultaneous real workloads and a 1.2x minimum speed;
  weight scheduling by the greater input/output pixel rate.
- Parse capability state as data. Never source cache contents as shell code.
- Preserve required-cache exits and the managed, opt-in degraded stream-copy
  fallback.
- Keep advanced arguments phase-scoped and array-based. Never use `eval`.
- The wrapper owns input structure, hardware/device selection, video encoder,
  hardware filters, and the fixed `-f mpegts pipe:1` destination.
- Never log source URLs or embedded credentials.
- Treat diagnostic I/O status 73 as fatal across every benchmark boundary;
  ordinary unsupported hardware paths remain candidate rejection, not I/O failure.
- Keep each trial's diagnostics distinct. Check cache writes and summary reads,
  publish the summary before purging evidence, and terminate owned benchmark
  children within bounded cleanup deadlines. Preserve failures for diagnosis.

## Development guidance

Review `DECISIONS.md`, `DEPENDENCIES.md`, current branch intent, relevant
history, and related Dispatcharr integration contracts before changing code.
Behavior changes require focused tests plus the applicable real FFmpeg,
hardware, container, live-stream, pipe, cache, and concurrency validation.

Do not import source from the unlicensed `FiveBoroughs/ffmpeg-asr` repository or
from copyleft/unlicensed implementations. Public interfaces and behavior may be
researched, but every implementation donor must be permissively licensed and
recorded in `PROVENANCE.md` with its exact source and use.

Decision capture is continuous. Before a decision-bearing commit, compare the
work with `DECISIONS.md`, ask one focused batch for unresolved authority, update
the record, review the complete change set for contradictions, and confirm a
future maintainer can understand the result without the conversation.

## Branch workflow

- `main` is production-ready and is the source of stable tags and Releases.
- `dev` integrates the next version.
- Short-lived `feature/*` and `fix/*` branches start from and return to `dev`.
- Beta tags use `vMAJOR.MINOR.PATCH-beta.N` on tested `dev` commits.
- Stable tags use `vMAJOR.MINOR.PATCH` on `main`.
- Record every live branch in `BRANCHES.md` before substantive work.

## Session completion and remote continuity

GitHub is the continuation source. Fetch first, resume from the exact owning
remote branch, preserve unrelated state, and use an isolated work branch.
Before handoff, update durable records, run available gates, commit all in-scope
work, push it, and prove the remote branch head equals the intended local
commit. A checkpoint does not authorize integration, tagging, releasing,
downstream pin changes, deployment, force-push, or branch deletion.

## Release requirements

Follow `RELEASE.md`. Keep `VERSION`, the script version, changelog section, tag,
release title, artifact name, and checksum synchronized. Never move a published
tag or replace an artifact. A release requires a fresh provenance/overlap audit
as well as behavior validation.

## Minimum validation

```bash
./scripts/validate.sh
```

Re-measure hardware capacity on deployment systems. Recorded capacities and
performance numbers are evidence, not portable defaults.

## Future-agent checklist

- Read this file, `DECISIONS.md`, `DEPENDENCIES.md`, `BRANCHES.md`,
  `PROVENANCE.md`, and relevant history.
- Use the local standards baseline during branch work; reconcile at the named
  bootstrap, standards-update and promotion boundaries.
- Confirm the branch base, target, version, and intended delivery path.
- Refresh dependency and downstream integration contracts.
- Keep decisions, user docs, tests, provenance, and branch records aligned.
- Run decision closure, contradiction review, and the chat-independence check.
- Validate proportionately to risk.
- Push every in-scope checkpoint and verify the exact remote head.
