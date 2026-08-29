# Bootstrap history review

Reviewed on 2026-08-29 for the `ffmpeg-adaptive` standalone bootstrap.

## Conversations and tasks

| Source | Review scope | Recovered decisions |
|---|---|---|
| `Copyright and Code Overlap Review` (`6a8f8330-fedc-83ea-b1af-21918f082f42`) | Complete, 2 pages / 20 turns | Attribution is not permission; keep the mixed-rights fork unreleased; prefer a fresh non-fork repository; record sources and source comparisons. |
| `FFMpeg-ASR` (`6a810a36-bf2c-83ea-bf41-b144d16ca1fb`) | Complete, 5 pages / 41 turns | Render-node fixes, representative benchmarking, 10-bit/HDR behavior, independent audio/video policy, constraints, deinterlace, concurrency, and multi-GPU intent. |
| `Add multi-GPU FFmpeg-ASR selection` (`01a01a9f-e65a-7ac3-95d0-430c44a35b16`) | Complete, 5 pages / 42 turns | Physical-device discovery, explicit overrides, 1.2x concurrent capacity, weighted scheduling, cache identity/reuse, persistent state, pipe input, and Dispatcharr contracts. |
| `Implement adaptive FFmpeg probing` (`01a043fd-8db6-7573-bbf9-17f61911f4ea`) | Complete, 16 pages / 154 turns | Fast/expanded/default metadata tiers, transport-failure boundary, selected-limit reuse, credential redaction, and CSPAN3/HDHomeRun validation. Unrelated Stream Sort turns in the same task history were read but excluded from this project's requirements. |
| `Update FFmpeg options and notes` (`01a03b76-b805-7de0-815f-559fa4341536`) | Complete, 3 pages / 25 turns | Phase-scoped advanced arguments, persistent cache/fallback contracts, map-all/lock fixes, beta/stable validation, and unresolved upstream licensing. |
| `Validate ffmpeg-asr rewrite` (`01a04dab-55bb-7801-873e-e3a4e993ad4d`) | Current task through bootstrap | Complete source/standards refresh, actual Dispatcharr 1080p/1080i/720p validation, final clean extraction, repository name and MIT direction. |

## Repository and standards evidence

- `matrix2669/workspace` standards and Git history through remote `main` commit
  `4102563425631edef07899ed1cc8fc95423e05f6`.
- Complete `projects/ffmpeg-asr/README.md` sidecar at that commit.
- `matrix2669/ffmpeg-asr` complete visible commit history through rewrite head
  `fe4fe93a4e1e5f81fb126a40739e123e4279f1dd`.
- Complete current `AGENT.md`, branch/release/provenance records, relevant ADR
  inventory, source tree, tests, and validation report.
- All 23 prior `matrix2669/ffmpeg-asr` ADRs; their standalone disposition is
  recorded in `docs/DECISION-MIGRATION.md`.
- Refreshed `FiveBoroughs/ffmpeg-asr` default branch at
  `99899d05affa501404ef2d2b926136a80bb87c75`; GitHub reports no repository
  license. Pull request 2, `Add MIT license`, remained open and unmerged.

## Exclusions and unavailable evidence

- Stream Sort implementation/debugging turns embedded in the adaptive-probing
  task were unrelated to this repository and did not define its behavior.
- Live stream credentials and persistent URLs are intentionally excluded from
  the repository and this ledger.
- No unavailable material source was discovered in the inventoried task list.
  The current task itself remains the live source for any uncommitted owner
  answers during bootstrap.
