# Decision migration from ffmpeg-asr

This matrix proves that relevant durable decisions from the prior
`matrix2669/ffmpeg-asr` record were either carried into the standalone project
or explicitly superseded. The source record was reviewed at rewrite head
`fe4fe93a4e1e5f81fb126a40739e123e4279f1dd`.

| Prior ADR | Subject | Standalone disposition |
|---|---|---|
| ADR-001 | Hybrid maintained-fork workflow | Superseded by new ADR-001 and ADR-012: this is a standalone clean-history project. |
| ADR-002 | Normalizer-first video copy | Carried into new ADR-007. HDR/10-bit flags are updated by new ADR-003. |
| ADR-003 | Optional composable constraints | Carried into new ADR-007; redundant aliases are intentionally removed by new ADR-003. |
| ADR-004 | Independent AAC/audio normalization | Carried into new ADR-008. |
| ADR-005 | Actual render-node discovery and explicit binding | Carried into new ADR-006 and `AGENT.md`. |
| ADR-006 | Representative per-accelerator benchmarking | Carried into new ADR-006 and `DEPENDENCIES.md`. |
| ADR-007 | Self-contained proportional multi-GPU routing | Carried into new ADR-006. |
| ADR-008 | Real concurrent capacity with 1.2x floor | Carried into new ADR-006. |
| ADR-009 | 1080p30-equivalent weighted load | Carried into new ADR-006. |
| ADR-010 | Hardware-identity cache reuse | Carried into new ADR-006 and ADR-009. |
| ADR-011 | Coordinated cache-only maintenance | Carried into new ADR-009. |
| ADR-012 | Exact non-seekable pipe replay | Carried into new ADR-005. |
| ADR-013 | Canonical source and bundled plugin | Superseded by new ADR-011: `ffmpeg-adaptive` is canonical. |
| ADR-014 | Semantic versions plus immutable source pins | Carried into new ADR-011 and ADR-012. |
| ADR-015 | Do not infer upstream license | Resolved by new ADR-001 and `PROVENANCE.md`; the new tree does not rely on an upstream grant. |
| ADR-016 | Persistent state outside replaceable installs | Carried into new ADR-009. |
| ADR-017 | Advanced arguments without shell evaluation | Carried into new ADR-010. |
| ADR-018 | Phase-scoped ownership | Carried into new ADR-010. |
| ADR-019 | Authoritative read-only cache validity | Carried into new ADR-009. |
| ADR-020 | Managed opt-in degraded proxy | Carried into new ADR-009. |
| ADR-021 | Auxiliary mappings and top-level lock ownership | Carried into new ADR-009 and ADR-010, including the later PID/start-time refinement. |
| ADR-022 | Metadata-validated adaptive probing | Carried into new ADR-005, including the rewrite's credential-redacting supervisor refinement. |
| ADR-023 | Modular clean replacement | Carried into new ADR-001, ADR-004 through ADR-010, `PROVENANCE.md`, and `RELEASE.md`. |

The prior branch-composition, unlicensed-fork release hold, and upstream
contribution workflow are historical evidence rather than active standalone
rules. Their relevant ownership and source-donor restrictions remain in
`AGENT.md`, `PROVENANCE.md`, and `RELEASE.md`.
