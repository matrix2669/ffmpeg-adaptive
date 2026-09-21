# beta.4 validation record — 2026-09-21

This record closes the beta.4 source, CI, and managed hardware evidence.

## Exact source and artifacts

- Wrapper tag: `v0.1.0-beta.4`.
- Wrapper source commit: `913a958fd5f9edc231c49a70539a09f611fdcc5a`.
- CI workflow definition commit: `10a6e4b8e16b66857df3b03a7bb6d0bb88fc9929`.
- Inspected wrapper source archive SHA-256:
  `39c3243a108c38be79bcc2209c6ae15abf20a9b745d0c2c98829d67847bea85e`.
- The published development plugin beta.5 is pinned to the immutable wrapper
  source and has public registry development entry
  `1e55f15ba3824f85209258b6b0dd3280c554924d`.

## CI

- Wrapper workflow run `35633440274` passed using ShellCheck 0.11.0 and
  separately validated the unchanged exact source commit above.
- Plugin tag CI run `35631993818` and development CI run `35631991578` passed.
- Registry CI run `35633913052` passed; its public registry root and detail
  records were verified.
- Historical wrapper runs `35631984969` and `35631983498` remain recorded as
  ShellCheck 0.9 SC2218 false-positive failures and are not release evidence.

## Tests and provenance

- The complete wrapper validation suite passed on the current checkout and on
  a detached worktree at `913a958fd5f9edc231c49a70539a09f611fdcc5a`.
- The suite included shell syntax, behavior, cache migration, lock ownership,
  adaptive probing, hardware command, benchmark-integrity, pipe replay, and
  CLI-contract tests.
- The beta.4 provenance audit found zero normalized non-comment matches against
  the recorded unlicensed upstream at both 32- and 48-character thresholds;
  the mixed-rights baseline had zero 48-character matches and seven isolated
  32-character test-fixture matches, with no runtime or benchmark match.
- The source archive was inspected from the exact immutable source commit;
  runtime state and Git history were excluded.

## Managed state and completed validation

- The official Dispatcharr 0.31.0 API installation of plugin beta.5 preserved
  settings, offered no update, and reported update flags false while no viewers
  were active.
- A zero-viewer benchmark started at `17:45:40 UTC`; stopped transcodes were
  `0` at the recorded check. It completed at
  `2026-09-21T17:51:16.719376+00:00` with return code 0, valid cache, no lock,
  and no live benchmark PID.
- Primary `renderD129`: VAAPI/HEVC Main10 decode and encode supported, capacity
  19, speed 14x. Secondary `renderD128`: capacity 14, speed 11.6x.
- The consolidated `benchmark-latest.log` was 1,508,339 bytes. No root
  candidate/capacity/10-bit logs or `.benchmark-run` directories remained.
- At 17:52 UTC, a bounded real-hardware launcher sent a previously generated
  four-second H.264 fixture through `pipe:0` to HEVC VAAPI 720p output for
  4.025 seconds. Full decode with `-xerror` reported no errors and measured
  120 frames.
- The final `17:52:25` snapshot had zero viewers, zero input/output
  transcodes, no FFmpeg/FFprobe processes, installed runtime and manifest
  beta.5 pinned to `913a958`, and an unchanged settings digest.

No live-provider channel was fetched and no actual profile was created. This is
bounded real-hardware and managed-launcher evidence, not a claim that a live
provider channel or actual user profile was exercised.
