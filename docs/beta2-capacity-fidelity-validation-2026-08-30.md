# Beta 2 capacity-fidelity validation

## Scope

This gate validates the `0.1.0-beta.2` correction on the production Intel
integrated GPU and Arc A310 before integration, tagging, downstream plugin
synchronization, registry publication, or installation. The exact candidate
tested after the final runtime change was
`bebd9e40f34066cd58e050132599822f8361ab50` on
`fix/benchmark-runtime-fidelity`.

## Defects found and corrected

The beta-1 benchmark initialized an encoder device but decoded the generated
Main10 fixture in software before uploading frames. Normal transcodes decode on
the selected GPU. Capacity therefore described a different workload. Runtime
also applied the globally fastest device's low-power and 10-bit-encode values
to whichever GPU the scheduler selected.

The first corrected full scan exposed two additional pre-tag problems:

1. An unstable 28-job Arc upper-bound probe had no wall-clock deadline and
   starved the host until it was rebooted. The final candidate terminates an
   expired level, rejects it, and grows unbounded levels by 50% instead of
   doubling them.
2. Independent per-device discovery selected H.264 for the iGPU and HEVC for
   Arc. Those capacities cannot both describe one auto-selected runtime codec.
   The final candidate rebenchmarks compatible secondary GPUs on the chosen
   global accelerator/codec before measuring capacity.

All defects were found before a tag, plugin pin, registry update, or managed
installation. The reboot cleared the isolated `/dev/shm` state; Dispatcharr
restarted normally. No production plugin source or profile was modified during
this gate.

## Deterministic and provenance gates

- `./scripts/validate.sh`: pass for `0.1.0-beta.2`.
- Workspace standards reconciliation: pass at
  `sha256:6456d4a722cfca0a03e6bce3d698208c844a114953c62d0fe757789d48f1c794`.
- Fresh normalized non-comment shell overlap:
  - unlicensed upstream `99899d05affa501404ef2d2b926136a80bb87c75`:
    zero matches at 32 and 48 characters;
  - mixed-rights baseline `7829924588336f1de07f18d944472c429a32c5b1`:
    five unchanged test-fixture lines at 32 characters and zero matches at 48
    characters.
- All 16 QSV/VAAPI, H.264/HEVC, normal/low-power one-run candidate
  combinations passed on the two Intel render nodes with hardware decoding.

## Capacity result

The accepted cache uses one common production path on both devices:

| Device | Path | Low power | Single speed | Confirmed capacity | Rejected next level |
|---|---|---:|---:|---:|---:|
| Arc A310 `/dev/dri/renderD129` | VAAPI/HEVC | 0 | 14.2x | 18 | 19 |
| Intel iGPU `/dev/dri/renderD128` | VAAPI/HEVC | 1 | 11.4x | 14 | 15 |

Every accepted level and the next rejected level used a 30-second confirmation
with a minimum 1.2x speed per simultaneous transcode. The cache status was
`valid`, both devices reported 10-bit decode/encode support, Arc was primary,
and the iGPU was secondary.

For context, the historical mixed-rights implementation reported Arc 18 and
iGPU 15 under its own VAAPI/HEVC policy. The corrected independent result is
therefore equal on Arc and one boundary stream lower on the iGPU. The earlier
managed beta cache's 15/11 VAAPI/H.264 result was not a hardware loss: it used
software decode during capacity measurement and did not bind runtime policy to
the measured device row.

An exploratory 17/17 result was discarded because the iGPU 17 belonged to its
independent H.264-best path while Arc 17 belonged to HEVC. The final 18/14
result is the first one in this beta cycle that is directly usable by the
single auto-selected HEVC runtime path.

## Actual Dispatcharr streams

The isolated candidate and cache were exercised through current Dispatcharr
stream records. The authorized read-only Django lookup kept the existing
container secret inside the container environment; it was not printed or
stored. Source addresses and account values were redacted from captured
diagnostics.

| Source | Direct result | `pipe:0` result | Frame/timestamp result |
|---|---|---|---|
| CBS 2 New York, H.264 1080p59.94 | HEVC 1920x1080 | HEVC 1280x720 | zero decode errors; 0/300 interlaced frames; monotonic, nonnegative DTS |
| PIX11 New York, MPEG-2 1080i29.97 | HEVC 1920x1080 deinterlaced | HEVC 1280x720 | zero decode errors; 0/147 interlaced frames; monotonic, nonnegative DTS |
| FOX 5 New York, H.264 720p59.94 | HEVC 1280x720 | HEVC 1280x720 | zero decode errors; 0/300 interlaced frames; monotonic, nonnegative DTS |

All six direct/pipe cases passed. Fast probing was accepted where metadata was
complete; the finite PIX11 pipe sample correctly expanded to the 2-second/2-MB
tier when the fast tier was incomplete.

## Live multi-GPU scheduling

Three staggered current streams proved that the runtime used the same policy
stored in each selected row:

- CBS 2 selected Arc `/dev/dri/renderD129`, capacity 18, low-power 0.
- FOX 5 selected iGPU `/dev/dri/renderD128`, capacity 14, low-power 1.
- PIX11 selected the loaded iGPU at 888 milli-units, capacity 14, low-power 1.

All three HEVC outputs probed and decoded successfully with zero decode errors.
An unrelated short CPU-only Dispatcharr analyzer was observed during the wait
for an idle window; it held no DRM descriptor, was ignored by the GPU
scheduler, and was not stopped or modified.

## Final state

The final privacy-safe process audit reported zero wrapper processes, zero
FFmpeg processes, and zero FFmpeg processes holding a DRM device. The isolated
candidate remains uninstalled. Publication and deployment remain separate
steps after this evidence is committed and the exact release tree is rechecked.
