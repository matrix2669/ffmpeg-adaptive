# Local AAC late-join validation, 2026-11-13

Canonical candidate: branch `fix/aac-side-late-join`, based on dev
`262f92b326c6b5259fecee2d4c68ef8e3a1fcd8a`. No publication, downstream pin
update, live settings change or deployment is part of this result.

## Results

- Exclusive full `scripts/validate.sh` passed on host FFmpeg 7.1.5 with
  ShellCheck 0.11.0, including all 20 shared-input tests. An earlier overlapping
  run's cancellation return-code failure is retained at
  `/tmp/ffsmart-aac-verified.log`; the exclusive gate passed without changing
  its deadline or assertion. A later exact-commit run reproduced the same
  failure without overlap. The fixed 0.3-second signal delay did not establish
  handler readiness. The fixture now waits, bounded by two seconds, for its
  unique upstream request before signaling, and kills/reaps on readiness failure.
  Existing one-second deadline cases, three-second cleanup bound and status/output
  assertions are unchanged. No shared-input runtime code changed. The failing
  exact-commit log remains `/tmp/ffsmart-c77dfdb-full-validation.log`.
- Policy and real-media tests passed inside the isolated existing container
  with FFmpeg 8.1.2; executable SHA-256
  `66d929368322861e8dcdbeb3f69e4ce8ddf89b6cc2d3c6e364424c00561bf86c`.
  No network or live media was used by these synthetic fixtures.
- Baseline side AAC used ADTS configuration 0 and failed parameter discovery at
  the tested late joins. Corrected AAC used configuration 6 and decoded at
  three packet-aligned offsets (half, third, quarter) at 48 and 44.1 kHz.
- Six distinct test tones retained channel routing; measured corresponding-tone
  amplitude was 0.7–1.3 times the AC3 reference, with each intended tone greater
  than five times any other channel tone. This is a bounded lossy-encoding check,
  not a bit-exact audio claim.
- A mixed source exercised side, back and stereo encoding with added
  `dynaudnorm=f=150:g=15`. Side output composed pan, async resampling and
  normalization; back/stereo composed resampling and normalization only.
- Compatible AAC copy was byte-identical after ADTS extraction. Explicitly
  adding a filter to a copy-only output remained an FFmpeg error.
- Actual wrapper output argv was captured by a transparent exec shim during a
  second passing pinned-runtime fixture run: five commands, including default
  side at both rates, normalized mixed audio, AAC copy and invalid filtered copy.
- Independent Astra review found no must-fix defect. Its advisory negative-map
  coverage was strengthened with exact order/count, removal without re-add,
  numeric negative mapping and per-output channel override assertions. Focused
  policy and ShellCheck checks passed after that test-only strengthening.

## Evidence locations

Private local logs: `/tmp/ffsmart-final-exclusive.log`,
`/tmp/ffsmart-pinned-aac-final.log`, `/tmp/ffsmart-pinned-argv.log`.
Pinned source snapshot and actual JSON argv are retained under
`/workspace/tivo-dispatcharr-bridge/artifacts/probe-discovery/` as
`smart-source-snapshot` and `smart-argv-evidence/commands.jsonl`.
A final exact-commit gate is run after checkpointing this report; its result is
reported separately rather than claiming a future pass here.

## Limits and delivery boundary

No live channel 505 playback acceptance is claimed. Synthetic MPEG-TS cuts emit
video dimension warnings while joining between sequence headers; the asserted
strict audio decode succeeds. This does not establish uninterrupted video at
arbitrary packet boundaries. Bash 3 compatibility was inspected and syntax
checked with installed Bash, not executed using Bash 3.

Only resolved mappings and known layout-preserving simple filter chains receive
correction. Arbitrary graphs and unresolved selectors conservatively retain
existing FFmpeg option behavior. Standard 5.1 labels the surround pair as back;
the user explicitly approved the one-to-one side-to-back convention. No channels
are mixed or dropped. Existing AAC-copy inputs that already lack initialization
are not repaired by this encoding-only change.

The Dispatcharr plugin's vendored runtime is unchanged. Publishing this canonical
source, updating its immutable downstream pin/version, and deploying require
separate approval and the corresponding exact-commit checks.
