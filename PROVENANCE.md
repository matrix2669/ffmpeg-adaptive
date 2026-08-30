# Provenance

This file records why the current `ffmpeg-adaptive` tree is suitable for an MIT
license from its owner. It is an engineering provenance record, not legal
advice or a guarantee that no claim can ever be made.

## Repository boundary

- This repository starts with a new Git root and is not a GitHub fork.
- No Git objects or commit ancestry are imported from
  `FiveBoroughs/ffmpeg-asr` or `matrix2669/ffmpeg-asr`.
- The runtime, benchmark tools, and behavior tests were imported only from the
  independently structured rewrite at `matrix2669/ffmpeg-asr` commit
  `fe4fe93a4e1e5f81fb126a40739e123e4279f1dd`.
- New standalone documentation and licensing were authored for this repository;
  the inherited upstream README was not imported.

## Functional authorities

| Source | Exact reference | Use | Expression copied |
|---|---|---|---|
| Workspace clean-rewrite sidecar | `matrix2669/workspace` commit `4102563425631edef07899ed1cc8fc95423e05f6`, `projects/ffmpeg-asr/README.md` | Behavior specification, source restrictions, prior-art and verification plan | No implementation |
| Independent rewrite | `matrix2669/ffmpeg-asr` commits `300a4707903c15f53c05b8ec8a379cf8fa22c2b5` and `fe4fe93a4e1e5f81fb126a40739e123e4279f1dd` | Runtime, benchmarks, behavior tests, and matrix2669-authored validation evidence | Yes, owned rewrite material moved into this MIT project |
| Existing mixed-rights baseline | `matrix2669/ffmpeg-asr` commit `7829924588336f1de07f18d944472c429a32c5b1` | Black-box compatibility and source-overlap comparison only | No intentional expression |
| Unlicensed upstream baseline | `FiveBoroughs/ffmpeg-asr` commit `99899d05affa501404ef2d2b926136a80bb87c75` | Functional history and source-overlap comparison only | No intentional expression |
| Project history | Sources inventoried in `docs/HISTORY-REVIEW.md` | Recover owner requirements and accepted behavior | No upstream implementation |

## Public technical references

| Source | Status | Use | Expression copied |
|---|---|---|---|
| [FFmpeg manuals](https://ffmpeg.org/documentation.html) | Official project documentation | CLI, filters, encoders, devices, and MPEG-TS behavior | No |
| [FFmpeg QSV example](https://github.com/FFmpeg/FFmpeg/blob/master/doc/examples/qsv_transcode.c) | FFmpeg repository license | QSV device/filter relationships | No |
| [Linux DRM sysfs ABI](https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-drm) | Kernel documentation | Render-node and hardware identity | No |
| [Intel compute-runtime device table](https://github.com/intel/compute-runtime/blob/master/shared/source/dll/devices/devices_base.inl) | MIT | Intel PCI identity reference | No |
| [Intel Arc A310 product information](https://www.intel.com/content/www/us/en/products/sku/227958/intel-arc-a310-graphics/overview.html) | Vendor documentation | Hardware capability context | No |
| [Jellyfish test media](https://larmoire.org/jellyfish/) | Public test media | Historical benchmarking prior art only; current tests generate bounded fixtures | No |

No GPL, copyleft, or unlicensed implementation was used as a donor for this
tree.

## Independent implementation choices

- Thin entry point with separate common, CLI, cache, hardware, probe, and
  policy modules.
- Strict data-only capability cache rather than executable assignments.
- Locally generated bounded fixtures and independent candidate/capacity
  orchestration.
- Hardware-signature reuse independent of render-node assignment.
- FFmpeg phase arrays and a fixed MPEG-TS stdout destination.
- Metadata-validated adaptive probing, diagnostic redaction, and exact stdin
  prefix replay.
- Black-box tests of commands, policy, status codes, cache states, locks,
  mapping, and managed-integration behavior.

## Source-overlap review

The final 2026-08-29 standalone audit compared normalized non-comment shell
source against both the unlicensed upstream and the pre-rewrite mixed-rights
baseline:

- Unlicensed upstream `99899d05affa501404ef2d2b926136a80bb87c75`:
  zero identical lines at both 32- and 48-character thresholds.
- Mixed-rights baseline `7829924588336f1de07f18d944472c429a32c5b1`:
  zero identical lines at the 48-character threshold and no multi-line run at
  the 32-character threshold.
- The seven isolated 32-character matches against the mixed-rights baseline
  are one-line test-fixture mechanics such as temporary fake-tool creation;
  none is runtime or benchmark implementation.

The standalone extraction also rewrote the earlier shared version-validation
plumbing and the two common runtime mechanics identified by the first rewrite
audit.

The fresh 2026-08-30 `0.1.0-beta.2` audit repeated the normalized non-comment
shell comparison after the hardware-path correction:

- Unlicensed upstream `99899d05affa501404ef2d2b926136a80bb87c75`:
  zero identical lines at both 32- and 48-character thresholds.
- Mixed-rights baseline `7829924588336f1de07f18d944472c429a32c5b1`:
  zero identical lines at the 48-character threshold and five isolated
  32-character matches. All five are unchanged test-fixture mechanics; none is
  runtime or benchmark implementation.
- The shared hardware-decoder constructor, device-policy eligibility, and
  selected-device capability changes introduced for this beta produced no new
  substantive overlap with either restricted comparison source.

Before the initial commit and every release, rerun the comparison against both
recorded baselines, inspect near-identical structure/comments/messages, and
record the exact result here. A mechanical match threshold is evidence, not a
legal substantial-similarity determination.

## Licensing conclusion

The current tree is offered under MIT by its stated copyright owner because it
contains the independently authored implementation, tests, and documentation
within the new repository boundary. The upstream project's open MIT pull
request remains unmerged and is not relied upon as permission.
