# Wattchmen Modeling Method

## Sources

- Main source: `knowledge/library/PDF/essay/Wattchmen-Watching the Wattchers.pdf`, Sections 3, 4, 5, and 6.
- Supporting comparison: `knowledge/library/PDF/essay/2021-MICRO-AccelWattch-Kandiah.pdf`.

## Energy Decomposition

Wattchmen decomposes measured GPU energy into:

```text
E_total = E_const + E_static + E_dynamic
```

Where:

- `E_const`: baseline device or board energy consumed even when no GPU work is issued.
- `E_static`: energy from GPU structures that are powered while a kernel is active but not necessarily switching.
- `E_dynamic`: energy attributable to executed instructions and memory hierarchy activity.

For a kernel or benchmark with runtime `T_exec`:

```text
E_total = (P_const + P_static) * T_exec + E_dynamic
```

Wattchmen uses the dynamic part as the right-hand side for the instruction energy solver.

## Dynamic Energy Linear Model

For one microbenchmark:

```text
E_dynamic = sum_i count_i * energy_i
```

Where:

- `count_i` is the executed count of SASS instruction `i`.
- `energy_i` is the unknown per-instruction dynamic energy.

For many microbenchmarks, this becomes:

```text
A x = b
```

Where:

- `A`: microbenchmark by instruction count matrix.
- `x`: per-instruction dynamic energy vector.
- `b`: measured dynamic energy for each microbenchmark.

Wattchmen maintains a square or controlled system by adding new benchmarks when adding new target instructions. It solves with non-negative constraints because instruction energy should not be negative.

## Why The System Approach Matters

A naive method would divide each microbenchmark's energy by the target instruction count. That is wrong because each benchmark includes:

- loop branch instructions,
- loop counter arithmetic,
- address arithmetic,
- loads/stores to feed or sink values,
- predicate setup,
- moves and register initialization,
- synchronization/barrier instructions for some classes.

Wattchmen's key rule is:

> Do not try to manually subtract all overhead from each benchmark. Instead, include overhead instructions in the global equation system and make sure they are covered by other benchmarks.

This allows ancillary instructions to receive their own energy attribution.

## Training Inputs

Each training microbenchmark must produce:

- measured power trace or total energy,
- runtime,
- SASS opcode counts,
- cache hit/miss rates for memory operations,
- launch configuration,
- target GPU identity and clocks,
- temperature and power limit metadata.

For H800, store both raw and normalized data:

- raw samples: timestamp, power, utilization, temperature, clocks.
- derived values: steady-state window, integrated energy, `E_const`, `E_static`, `E_dynamic`.
- profiler values: `sass__inst_executed_per_opcode_with_modifier_all` if available, otherwise the closest supported metric.

## Constant And Static Energy

Recommended initial H800 procedure:

1. Measure idle power before microbenchmark launch to estimate `P_const`.
2. Run a NANOSLEEP or near-no-op active kernel that keeps the GPU active with minimal dynamic switching to estimate `P_const + P_static`.
3. Use a fixed active-SM/lane configuration for training benchmarks.
4. Treat the difference between active-no-op power and idle power as initial `P_static`.
5. Validate by checking whether residuals of the dynamic linear model remain small.

The Wattchmen paper reports that active-but-not-doing-work behavior was stable across their Volta/Ampere/Hopper clusters. Do not assume the same numeric value on H800.

## Instruction Table

The trained output should be an instruction energy table with at least these fields:

| Field | Meaning |
| --- | --- |
| `arch` | GPU architecture or target, e.g. `sm90_h800`. |
| `cuda_version` | CUDA toolkit used to compile microbenchmarks. |
| `driver_version` | NVIDIA driver version. |
| `opcode_key` | SASS opcode plus selected modifiers. |
| `opcode_base` | Basic opcode without modifiers. |
| `bucket` | Fallback group such as INT_ALU, FP_ALU, SHARED_LOAD, GLOBAL_LOAD, TENSOR. |
| `energy_j` | Dynamic energy per executed instruction instance. |
| `source` | `direct`, `grouped`, `scaled`, or `bucketed`. |
| `benchmark_ids` | Microbenchmarks that constrain this value. |
| `notes` | Compiler or metric caveats. |

## Coverage Extension

Wattchmen uses three coverage mechanisms.

### Scaling

Use for memory instructions with different data widths or hierarchy levels when not every variant has a direct benchmark.

Example policy:

- Directly benchmark representative load/store widths: 8, 16, 32, 64, 128 bits per thread.
- Directly benchmark L1-hit, L2-hit, and DRAM-miss patterns for core global load/store cases.
- If `LDG.E.64` is known at L1 and DRAM but `LDG.E.128` is missing at DRAM, estimate from the known width ratio or known hierarchy ratio, and mark as `scaled`.

### Grouping

Use when modifiers are expected to have small energy effect.

Examples:

- Eviction/cache policy modifiers: treat `STG.E.EF.64` like `STG.E.64` if no direct evidence contradicts it.
- Predicate operation modifiers: group variants such as `ISETP.GE.AND`, `ISETP.LE.OR`, and related compare/predicate forms if measured energies are close.
- Tensor step sequences: group multi-step tensor instruction sequences when hardware emits fixed step modifiers for one logical operation.

Grouping must be documented and reversible; keep raw opcode counts before grouping.

### Bucketing

Use when an opcode is not directly measured but belongs to a known instruction family.

Example buckets:

- integer ALU: `MOV`, `LOP3`, `IADD3`, `IMAD` variants,
- floating-point ALU: `FADD`, `FMUL`, `FFMA`, `DADD`, `DMUL`, `DFMA`,
- predicate/control: `ISETP`, `PLOP3`, `BRA`, `BSYNC`,
- shared memory: `LDS`, `STS`, `LDSM`,
- global/local memory: `LDG`, `STG`, `LDL`, `STL`,
- tensor: `HMMA`, `MMA`, `WGMMA`/`HGMMA`,
- async/barrier: `CP.ASYNC`, `LDGSTS`, `TMA`, `MBARRIER`.

For H800, any bucketed value must be labeled as approximate until direct microbenchmarks are added.

## Prediction Formula

For a target kernel:

```text
E_pred =
    (P_const + P_static) * T_kernel
  + sum_direct count_i * energy_i
  + sum_grouped count_j * grouped_energy_j
  + sum_scaled count_k * scaled_energy_k
  + sum_bucketed count_l * bucket_avg_l
```

For this project, a target "kernel" may be a full operator instance such as GEMM, FlashMLA, or a FlashAttention version. Operator-level prediction should aggregate all GPU kernels launched by that operator unless the experiment explicitly isolates one kernel.

Memory instructions need cache decomposition:

```text
count_L1   = count_total * L1_hit_rate
count_L2   = count_total * (1 - L1_hit_rate) * L2_hit_rate_given_L1_miss
count_DRAM = count_total - count_L1 - count_L2
```

Use the exact hit-rate metrics available from Nsight Compute for the chosen GPU/toolkit. Record metric names in the run log.

## Solver Requirements For Later Implementation

- Use a non-negative least-squares or constrained linear solver.
- Keep raw matrix `A`, vector `b`, solution `x`, residuals, and rank/condition diagnostics.
- Flag poorly constrained opcodes.
- Re-run the solver after each new benchmark category is added.
- Compare residuals across repeated measurement runs; high residuals usually mean unstable power, bad opcode counts, or a benchmark that did not emit the intended SASS.

## First H800 Model Milestone

Build an initial model with a small complete system:

- `NOP`/active baseline.
- integer ALU: `MOV`, `IADD3`, `IMAD`, `LOP3`.
- FP ALU: `FADD`, `FMUL`, `FFMA`, `DADD`, `DMUL`, `DFMA`.
- control: `ISETP`, `BRA`.
- shared memory: `LDS`, `STS`.
- global memory: `LDG`, `STG` at several widths and L1/L2/DRAM behaviors.
- tensor: one FP16/BF16 WGMMA or HGMMA path plus required `LDSM`/shared-memory setup.
