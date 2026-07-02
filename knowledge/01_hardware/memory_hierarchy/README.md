# Memory Hierarchy

This directory stores cross-cutting memory hierarchy knowledge for performance and power prediction.

## Why It Matters

For Wattchmen-style modeling, a memory SASS opcode is not enough. The same load/store instruction can consume different energy depending on:

- data width,
- coalescing,
- L1 hit,
- L2 hit,
- HBM access,
- shared-memory bank conflicts,
- async copy path,
- TMA path.

## Required Notes To Build Later

- H800 L1/shared memory behavior.
- H800 L2 hit/miss benchmarks.
- HBM bandwidth and power microbenchmarks.
- Cache metrics from Nsight Compute and how they map to `LDG`, `STG`, `LDS`, `STS`, `LDSM`, `LDGSTS`, and TMA.
- Operator-specific memory behavior for GEMM, FlashMLA, and FlashAttention v3.
