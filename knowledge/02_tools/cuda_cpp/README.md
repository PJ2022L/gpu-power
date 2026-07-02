# CUDA C++

## Role

CUDA C++ owns low-level benchmark binaries: custom microbenchmarks, kernel harnesses, and C++ wrappers used when Python overhead or framework behavior would obscure measurement.

It does not own NVCC flag policy, PTX theory, SASS taxonomy, or NVML API details.

## Harness Responsibilities

CUDA C++ benchmarks should:

- take GPU ID, iteration count, warmup count, and data size as CLI arguments,
- print all arguments and launch configuration to stdout/log,
- use CUDA events for performance timing only, not power measurement,
- expose a deterministic sink/checksum to prevent dead-code elimination,
- return nonzero on CUDA errors,
- support short profiler mode and long energy mode.

## Recommended Metadata

Each binary should print:

```text
benchmark_name=
target_operator_or_opcode=
gpu_id=
grid_dim=
block_dim=
shared_memory_bytes=
iterations=
warmup_iterations=
data_size_bytes=
```

## Boundary With Microbenchmarks

Microbenchmark design rules live in `00-reference_essay/wattchmen/03-microbenchmark-design.md`. This directory only records CUDA C++ harness conventions.
