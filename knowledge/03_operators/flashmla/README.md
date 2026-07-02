# FlashMLA

## Role

FlashMLA is one of the target operator families for H800 performance and power prediction. It should drive coverage for MLA-specific attention kernels and memory movement patterns.

## What To Track

- Representative decode/prefill shapes.
- KV/cache layout and memory access pattern.
- Dtypes for Q/K/V and accumulation.
- Dominant SASS classes: tensor instructions, global loads, shared-memory staging, async copy/TMA if used, barriers, reductions.
- Memory behavior: HBM traffic, L2 reuse, cache hit rates, shared-memory pressure.
- Validation target: predicted power within 15% of measured FlashMLA power.

## Initial Questions

- Which FlashMLA implementation and commit will be used?
- What shapes correspond to the intended model workload?
- Which kernels are launched per operator call, and should energy be aggregated across all of them?
