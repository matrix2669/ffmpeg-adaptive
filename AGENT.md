# Agent Guidance

## Purpose

`ffmpeg-adaptive` is the standalone matrix2669 source for an adaptive live
stream normalizer implemented in Bash. It owns its full source, documentation,
tests, licensing, branches, and release lifecycle.

The command remains `ffmpeg-smart.sh` for compatibility with existing
Dispatcharr profile definitions. A downstream integration must pin an immutable
commit and checksum; changes here never silently alter an installed plugin.

## Workspace Standards Reconciliation Gate

Before substantive work:

1. Locate the maintained local `matrix2669/workspace` checkout. Its
   `AI-INSTRUCTIONS.md`, `AGENT-STANDARD.md`, and Git history must be readable.
2. Run `<workspace>/scripts/reconcile-standards --check .` from this repository.
3. If `WORKSPACE-STANDARDS.yaml` is missing, pending, malformed, or stale, stop and run
   `<workspace>/scripts/reconcile-standards --diff .`.
4. Review the standards change against this complete file, `DECISIONS.md`,
   `DEPENDENCIES.md`, `BRANCHES.md`, `RELEASE.md`, code/configuration contracts,
   related projects, and current user instructions.
5. A contradiction blocks work. Ask focused questions to establish which
   authority is correct, record supersessions in `DECISIONS.md`, and realign
   every affected artifact.
6. Only after no contradiction remains, run `<workspace>/scripts/reconcile-standards
   --apply --confirm-reviewed-no-conflicts .`.

Missing standards or workspace Git history is a hard block. Exceptions require
explicit user approval and a dedicated section here with scope, rationale,
authority, date, and removal trigger.

## Architecture

- `ffmpeg-smart.sh` is the thin compatibility entry point.
- `lib/ffsmart-cli.sh` parses and validates policy and phase-scoped FFmpeg
  arguments.
- `lib/ffsmart-cache.sh` owns the strict data-only cache schema and validity.
- `lib/ffsmart-hardware.sh` discovers devices, tests candidates, measures
  concurrent capacity, and selects visible GPUs.
- `lib/ffsmart-probe.sh` handles URL and non-seekable input probing, adaptive
  metadata tiers, prefix replay, and credential-safe diagnostics.
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
- Run the standards reconciliation gate.
- Confirm the branch base, target, version, and intended delivery path.
- Refresh dependency and downstream integration contracts.
- Keep decisions, user docs, tests, provenance, and branch records aligned.
- Run decision closure, contradiction review, and the chat-independence check.
- Validate proportionately to risk.
- Push every in-scope checkpoint and verify the exact remote head.
