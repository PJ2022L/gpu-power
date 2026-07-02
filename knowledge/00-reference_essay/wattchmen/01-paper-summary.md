# Wattchmen Paper Summary

## Sources

- Main source: `knowledge/library/PDF/essay/Wattchmen-Watching the Wattchers.pdf`
- Supporting comparison source: `knowledge/library/PDF/essay/2021-MICRO-AccelWattch-Kandiah.pdf`

## Problem

Modern GPU clusters are power constrained, but most available energy tools are too coarse for application optimization. Vendor tools such as NVML expose device-level power/energy. They do not directly explain which SASS instructions or memory hierarchy behaviors dominate a kernel's energy.

Wattchmen addresses this by building a per-instruction GPU energy model from real-hardware measurements. The model is designed to be:

- Fine-grained: attributes energy to compute, memory, and control-flow instructions.
- Flexible: retrainable for different GPU generations and cooling systems.
- Hardware-grounded: uses measured power/energy traces and profiler-derived instruction counts.

## Central Idea

Wattchmen constructs a dynamic energy table for SASS instructions. For a workload, it predicts total energy as:

- constant energy from idle board/device power over runtime,
- static energy from powered but not switching GPU resources over runtime,
- dynamic energy from executed instructions and memory hierarchy behavior.

The key insight is not to isolate every instruction perfectly. A microbenchmark for one instruction inevitably contains address arithmetic, branches, moves, loads/stores, loop overhead, and other ancillary instructions. Wattchmen treats all microbenchmarks together as a system of equations. An ancillary instruction in one benchmark can be the target instruction in another benchmark, allowing the solver to assign energy to each opcode consistently.

## Workflow

Training phase:

1. Run a suite of hand-tuned microbenchmarks.
2. Collect power or energy traces for each microbenchmark.
3. Collect SASS opcode counts and cache hit rates.
4. Remove constant/static energy to obtain dynamic energy.
5. Solve a non-negative linear system to derive per-instruction dynamic energy.
6. Build an instruction energy table and coverage-extension rules.

Prediction phase:

1. Profile the target application's execution time.
2. Collect SASS opcode counts, preserving modifiers when useful.
3. Collect cache hit/miss behavior for memory instructions.
4. Add constant/static energy by runtime.
5. Add dynamic energy from direct instruction matches, grouped/scaled variants, or bucket estimates.
6. Report total energy and per-opcode attribution.

## Evaluation Claims From The Paper

Wattchmen reports lower error than AccelWattch and Guser on V100, and it generalizes across V100 cooling variants plus A100/H100 after retraining.

Important numbers reported in the paper:

- V100 air-cooled: Wattchmen-Pred MAPE around 14%.
- Summit water-cooled V100: MAPE around 15%.
- A100: MAPE around 11%.
- H100: MAPE around 12%.

These numbers should be treated as paper-reported baselines, not expected H800 results. H800 reproduction must train its own table.

## Difference From AccelWattch

AccelWattch is a component-level power model integrated with simulation and hardware counters. It estimates power over time windows and maps instructions to microarchitectural components.

Wattchmen differs in the target abstraction:

- Wattchmen solves for instruction-level energy on the measured system.
- Wattchmen emphasizes steady-state long-running measurements.
- Wattchmen avoids relying on a fixed architecture component model tuned on another card.
- Wattchmen directly uses SASS opcode counts and cache behavior for prediction.

For H800, this means AccelWattch is only a reference for benchmark structure and measurement scripts. The reproduction should build a new H800 SASS-level energy table.

## Limitations To Carry Forward

- SM activity: training assumes all SMs and lanes are saturated. Predictions for kernels with partial occupancy or inactive SMs may over-attribute static energy.
- Pipeline attribution: SASS instructions flow through deep pipelines, and instruction overlap can blur true per-instruction energy.
- Measurement granularity: NVML power/energy interfaces are coarse relative to sub-millisecond kernels. Long steady-state microbenchmarks reduce this issue.
- Compiler instability: inline PTX does not guarantee exact SASS. CUDA version, compiler flags, and target architecture can change emitted instructions.
- Single-GPU focus: Wattchmen does not model inter-GPU communication energy.
- Profiler overhead: SASS opcode and cache profiling should be collected separately from energy traces.

## H800 Implication

For H800, reproduce the methodology rather than the exact V100/A100/H100 tables. The operator-level project target is to predict GEMM, FlashMLA, FlashAttention v2, FlashAttention v3, and FlashAttention v4 power within 10% of measured operator power. The first milestone should be a small but complete instruction table covering:

- common integer and floating-point ALU instructions,
- branch/predicate/control-flow instructions,
- shared/global/local/constant memory instructions,
- L1/L2/DRAM hit/miss variants,
- Hopper tensor instructions such as WGMMA/HGMMA and related load/store/barrier instructions.
