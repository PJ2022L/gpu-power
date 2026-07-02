# Toolchain Knowledge

This directory documents the toolchain needed to build, inspect, profile, and measure H800 operator power.

## Responsibility Split

- `python_torch/`: Python/PyTorch operator harnesses and shape/dtype orchestration.
- `cuda_cpp/`: CUDA C++ harnesses, custom kernels, and benchmark binaries.
- `nvcc/`: compiler flags, architecture targets, and build reproducibility.
- `ptx/`: PTX as intermediate ISA and inline PTX constraints.
- `sass/`: final machine instruction inspection and opcode taxonomy.
- `ncu_nsight_compute/`: kernel-level metrics, SASS opcode counts, cache metrics.
- `nsight_systems/`: timeline, kernel launch decomposition, CPU/GPU range alignment.
- `nvml/`: power, energy, clock, temperature, and utilization measurement APIs.

## Non-Overlap Rule

Each subdirectory owns one tool layer. For example, SASS opcode meanings belong in `sass/`, while collecting opcode counts belongs in `ncu_nsight_compute/`. Power APIs belong in `nvml/`, while operator benchmark shapes belong in `03_operators/`.

## Project Workflow

1. Use `python_torch/` or `cuda_cpp/` to run operator workloads.
2. Use `nsight_systems/` to identify actual kernels launched by the operator.
3. Use `ncu_nsight_compute/` to collect per-kernel SASS counts and memory metrics.
4. Use `sass/` and `ptx/` to understand emitted instructions and compiler lowering.
5. Use `nvml/` to measure energy and clock/thermal state.
6. Use `nvcc/` rules to keep builds reproducible.
