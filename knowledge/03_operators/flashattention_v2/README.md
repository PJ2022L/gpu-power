# FlashAttention v2

## Role

FlashAttention v2 is a target attention operator family for H800 performance and power prediction. It should help establish baseline attention SASS-class coverage before newer versions.

## What To Track

- Forward and backward kernels, if both are in scope.
- Sequence lengths, head dimensions, batch/head counts.
- Causal vs non-causal mode.
- Dtypes: FP16, BF16, FP8 if applicable.
- Dominant SASS classes: global loads/stores, shared-memory operations, tensor instructions, reductions, exponentials/softmax-related instructions, barriers.
- Validation target: predicted power within 10% of measured FlashAttention v2 power.

## Initial Questions

- Which implementation and commit will be profiled?
- Are dropout/backward kernels in scope, or only inference forward?
- Which shape set best represents the target workloads?
