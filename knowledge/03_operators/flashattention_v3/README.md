# FlashAttention v3

## Role

FlashAttention v3 is a target attention operator family, likely more Hopper-oriented than v2. It should drive coverage for Hopper-specific tensor and async-memory instruction classes.

## What To Track

- Hopper-specific code paths.
- WGMMA/HGMMA usage.
- TMA or async copy usage.
- Barrier and pipeline structure.
- Sequence/head-dimension shape set.
- Dominant SASS classes and missing microbenchmarks.
- Validation target: predicted power within 10% of measured FlashAttention v3 power.

## Initial Questions

- Which v3 implementation and commit will be used?
- Which H800-specific optimizations are enabled?
- Does the kernel use TMA, WGMMA/HGMMA, or custom SASS/inline PTX?
