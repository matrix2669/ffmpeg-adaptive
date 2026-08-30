# Branches

This ledger records why every current branch exists. GitHub remains
authoritative for live refs, commits, pull requests, and checks.

## Maintenance rules

- Add a record before the first substantive commit on a new branch.
- Keep purpose, scope, base, target, validation, and disposition current.
- Verify live heads before acting; `git status` is not remote proof.
- Before deleting a branch, transfer user-visible results to `CHANGELOG.md` and
  durable rationale to `DECISIONS.md`, then remove its record.

## Branch index

| Branch | Type | Status | Base | Target | Purpose |
|---|---|---|---|---|---|
| `main` | long-lived | active | clean root | stable releases | Production-ready standalone project history. |
| `dev` | long-lived | active | `main` | `main` | Integrate and validate the next version after bootstrap. |
| `feature/standalone-parity-validation` | short-lived | integrated | `dev@3256799` | `dev` | Record the repeat old/rewrite/standalone comparison against the standalone repository. |
| `feature/v0.1.0-beta.1-release` | short-lived | integrated | `dev@4a88851` | `dev` | Prepare the first immutable standalone beta tag for downstream plugin synchronization. |

## Branch records

### `main`

- Type: long-lived
- Status: active
- Created: 2026-08-29
- Purpose: hold the independently authored MIT-licensed standalone project.
- Initial scope: runtime, benchmarks, behavioral tests, governance,
  provenance, and 2026-08-29 validation evidence.
- Out of scope: tags, GitHub Releases, deployment, and downstream plugin pin
  changes.
- Validation: `./scripts/validate.sh`, fresh source-overlap audit, and the live
  evidence in `docs/validation-2026-08-29.md`.
- Related decisions: ADR-001 through ADR-012.

### `dev`

- Type: long-lived
- Status: active
- Base/target: `main` / `main`
- Purpose: integrate post-bootstrap changes for the next beta or stable
  version.
- Current release candidate: `0.1.0-beta.1`, including the standalone parity
  evidence and synchronized release metadata.
- Validation: complete repository suite, repeated Intel iGPU/Arc A310 and
  Dispatcharr 1080p/1080i/720p comparison, standards reconciliation, fresh
  source-overlap audit, and inspected runtime archive.

### `feature/standalone-parity-validation`

- Type: short-lived
- Status: integrated
- Created: 2026-08-29
- Base/target: `dev@3256799` / `dev`
- Purpose: preserve the repeat comparison of the old baseline, accepted clean
  rewrite, and standalone `ffmpeg-adaptive` tree.
- Scope: documentation of deterministic suites, fresh hardware discovery,
  controlled fixtures, captured and current Dispatcharr streams, scheduling,
  software fallback, performance, and final process/privacy audits.
- Out of scope: runtime changes, merge, tag, release, deployment, Dispatcharr
  configuration, and downstream pin changes.
- Validation: `./scripts/validate.sh`, workspace standards reconciliation, and
  the source-overlap audit; full evidence is recorded in
  `docs/standalone-parity-validation-2026-08-29.md`.
- Disposition: integrated into `dev` for `v0.1.0-beta.1`.

### `feature/v0.1.0-beta.1-release`

- Type: short-lived
- Status: integrated
- Created: 2026-08-30
- Base/target: `dev@4a88851` / `dev`
- Purpose: set the synchronized beta version after the standalone parity gate
  and prepare the exact runtime tree for immutable downstream consumption.
- Scope: version metadata, changelog, release archive inspection, checksum,
  full repository validation, standards reconciliation, and fresh provenance
  audit.
- Out of scope: runtime behavior changes, stable promotion, plugin source
  changes, registry publication, and deployment.
- Expected outcome: validated `v0.1.0-beta.1` tag on `dev`, with no GitHub
  prerelease unless separately approved.
- Disposition: integrated into `dev`; the final validated `dev` commit is the
  immutable `v0.1.0-beta.1` tag target.
