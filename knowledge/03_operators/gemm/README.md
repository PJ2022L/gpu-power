# GEMM

## Role

GEMM is the baseline dense linear algebra operator for H800 performance and power prediction. It is the first operator family to use for validating tensor-core SASS-class coverage.

## What To Track

- Representative shapes: square GEMM, tall-skinny, batched, transformer MLP shapes.
- Dtypes: FP16, BF16, TF32, FP8 if supported by the implementation.
- Implementations: cuBLAS, CUTLASS, local kernels.
- Dominant SASS classes: WGMMA/HGMMA, LDSM, shared memory load/store, global load/store, async copy, barriers.
- Memory behavior: global-to-shared staging, shared-memory bank conflicts, L2 reuse, HBM traffic.
- Validation target: predicted power within 15% of measured GEMM power.

## Initial Questions

- Which GEMM implementation will be the reference: cuBLAS, CUTLASS, or local kernels?
- Which shapes are representative of the target workload?
- Does the implementation emit WGMMA/HGMMA on H800 for the selected dtypes?
