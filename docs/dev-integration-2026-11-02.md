# Development integration evidence — 2026-11-02

## Candidate and scope

The observed canonical dev baseline is
`5ed306892edfb27f25736eaf938edbd94ff5a8c0`. The accepted runtime candidate
`bb834684eb2c513e832c43ba6dbc773d5af10cbc` is seven commits ahead, incorporating
conditional video policy, shared input, configurable/preferred copy and opaque
TS detection. The proposed integration adds delivery documentation only to that
runtime tree; the resulting exact commit requires fresh full CI before dev moves.
This report preserves preparation evidence. The final workspace delivery record
is authoritative for the accepted commit, exact CI run and verified remote dev
head; this preparation snapshot does not assert those later outcomes.

Original runtime evidence: exact-source [Validate run 41103493960](https://github.com/matrix2669/ffmpeg-adaptive/actions/runs/41103493960)
succeeded for `bb834684eb2c513e832c43ba6dbc773d5af10cbc`; its independent
implementation review was accepted. Prior local validation covered all 20
shared-input methods as recorded in ADR-021. Those results are retained as
baseline evidence and are not a pass for the new documentation candidate.

## Standards reconciliation

Reviewed the complete workspace standards diff from
`sha256:9dcd9b79c959505a7d14c3d979124862e32748eda39b8f655cd712559757e8fe`
to `sha256:687a86e54c66c51f4c4e53f5c8e04fb6df59f6a88f82ed19ec5450eb53c03eaa`
against the complete local agent guidance, accepted decisions, branch/release,
dependency and provenance contracts, runtime defaults and downstream plugin
ownership/pin requirements. The changes concern lifecycle reconciliation,
established-project history scope, approval continuity, exact-SHA evidence and
durable status checkpoints. Replaced the outdated per-task gate; ADR-022
explicitly supersedes the former implementation-only integration exclusions.
No runtime/default, dependency, licensing or release contradiction remains.
The applied manifest is recorded only after this review.

## Local preparation checks

Both projects' standards reconciliation checks and documentation whitespace
checks passed. Canonical `./scripts/validate.sh` passed its shell and preceding
behavior gates, then stopped at shared-input fixture setup because the sandbox
denied binding `127.0.0.1`. Its 20 shared-input methods did not execute in this
local attempt. The plugin ran 80 tests: 79 passed and its proxy-only fixture
failed for the same loopback permission; compilation, JSON, Bash syntax and
offline eight-file source verification passed. These environment-limited local
attempts are not full-suite passes and do not replace exact-candidate CI.

## Historical acceptance state at preparation

- New documentation-candidate exact-SHA CI: pending at preparation.
- Dev fast-forward and fresh remote-head verification: pending at preparation.
- Plugin already bundles canonical `bb834684eb2c513e832c43ba6dbc773d5af10cbc`;
  this integration does not repin or repackage an existing immutable beta.
- Main, versions, tags, Releases, registries, installation, profiles/defaults,
  provider operations and branch deletion are outside this request.

The final workspace closeout records the accepted candidate, full successful CI
and verified remote dev head. Consult that final delivery record for current
acceptance rather than treating the preparation-time pending items above as live
status. Do not infer publication or installed runtime changes from dev movement.
