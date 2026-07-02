# Nsight Systems

## Role

Nsight Systems owns timeline-level analysis: which kernels an operator launches, their order, CPU/GPU ranges, CUDA API overhead, and synchronization boundaries.

It does not own per-kernel SASS metrics; that belongs in `../ncu_nsight_compute/`.

## Why It Matters

GEMM and FlashAttention-style operators may launch multiple kernels depending on implementation, shape, dtype, and framework settings. Operator-level power prediction must aggregate the same kernel set that is measured in the power run.

## What To Capture

For each operator harness:

- kernel names,
- launch count,
- kernel durations,
- CUDA API calls,
- NVTX ranges if available,
- synchronization points,
- warmup vs measured iterations.

## Minimal Command Pattern

```bash
nsys profile --trace=cuda,nvtx,osrt \
  --output operator_timeline \
  python run_operator.py <args>
```

Use the resulting timeline to decide which kernels should be passed to Nsight Compute for detailed SASS profiling.
