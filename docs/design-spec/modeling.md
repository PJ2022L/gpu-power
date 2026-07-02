# Modeling Design Spec

This document defines the first H800 Wattchmen-style model boundary. It is a design contract for Phase 3 fitting and Phase 4 prediction, not a record of one experiment.

## Sources

- Wattchmen paper: `knowledge/library/PDF/essay/Wattchmen-Watching the Wattchers.pdf`, especially Section 3.3.1 and Section 6.
- Knowledge summary: `knowledge/00-reference_essay/wattchmen/02-modeling-method.md`.
- Measurement protocol: `knowledge/00-reference_essay/wattchmen/04-measurement-protocol.md`.
- Power environment spec: `docs/design-spec/power_measurement_environment.md`.

## Wattchmen Boundary

Wattchmen decomposes measured energy as:

```text
E_total = E_const + E_static + E_dynamic
E_total = [(P_const + P_static) * T_exec] + E_dynamic
```

The dynamic term is then fitted from SASS instruction counts:

```text
E_dynamic = sum_i count_i * energy_i
A x = b
```

`b` is measured dynamic energy after subtracting constant and static energy. `x` is the non-negative per-SASS-class dynamic energy table.

## V1 H800 Assumptions

### Constant Energy

V1 treats `P_const` as a session-level idle baseline:

```text
E_const = P_const_idle * T_exec
```

Source:

- pre-run idle NVML power window on the target GPU,
- no unrelated process on the target GPU,
- same clock/power policy as the measurement session where possible.

`P_const` is not fitted per instruction and is not absorbed into dynamic SASS energy.

### Baseline Artifacts

Baseline collection is an explicit precondition for Phase 3. Use `scripts/collect_baselines.sh` before fitting:

```bash
scripts/collect_baselines.sh configs/power/nvml_policy.yaml idle
scripts/collect_baselines.sh configs/power/nvml_policy.yaml active_noop -- <active-no-op-or-nanosleep-command>
```

Required raw artifacts:

```text
experiments/raw/baseline_power/<idle_baseline_id>/
  metadata.yaml
  power_trace.csv
  summary.yaml
  repeatability.yaml
experiments/raw/baseline_power/<active_noop_baseline_id>/
  metadata.yaml
  power_trace.csv
  summary.yaml
  repeatability.yaml
```

Phase 3 must record which baseline IDs were used to derive `P_const_idle` and `P_static_full_activity`.

### Static Energy

V1 treats `P_static` as a full-activity active baseline:

```text
P_static_full_activity = P_active_noop_full_sm - P_const_idle
E_static = P_static_full_activity * T_exec
```

Source:

- NANOSLEEP, active-no-op, or equivalent low-switching kernel,
- full-SM and full-warp saturation when possible,
- same power/clock policy as microbenchmark and operator power runs.

This follows Wattchmen's practical assumption that, when all threads and all SMs are active, static power can be treated as fixed and multiplied by execution time.

### Dynamic Energy

V1 computes dynamic energy for each microbenchmark as:

```text
E_dynamic_measured =
    E_total_measured
  - (P_const_idle + P_static_full_activity) * T_exec
```

The solver uses:

```text
A_microbench_by_sass * energy_sass = E_dynamic_measured
```

Default solver:

- non-negative least squares,
- save `A`, `b`, solution, residuals, and coverage diagnostics,
- preserve raw opcode counts before grouping/scaling/bucketing.

## What V1 Does Not Model

V1 intentionally does not include:

- per-SM occupancy scaling for static energy,
- per-warp or active-lane static correction,
- voltage/frequency energy model beyond fixed or recorded clocks,
- temperature-dependent energy correction,
- inter-GPU communication energy,
- profiler overhead in energy runtime,
- per-instruction static energy.

These are excluded to keep the first model faithful to Wattchmen's basic decomposition and to avoid inventing H800-specific factors before measurement.

## Operator Prediction Rule

For one operator instance:

```text
E_operator_pred =
    (P_const_idle + P_static_full_activity) * T_operator
  + sum_direct count_i * energy_i
  + sum_grouped count_j * energy_group_j
  + sum_scaled count_k * energy_scaled_k
  + sum_bucketed count_l * energy_bucket_l
```

Phase 1 provides operator kernel list, SASS counts, and memory/cache behavior. Phase 4 separately measures `T_operator` and operator power/energy in non-profiled runs.

If an operator launches multiple kernels, aggregate all kernels launched by the operator call unless an execution plan explicitly isolates one kernel.

## Memory Hierarchy Rule

Memory dynamic energy is not opcode-only. A global load/store must be split by width and hierarchy behavior when metrics allow:

```text
count_L1   = count_total * L1_hit_rate
count_L2   = count_total * (1 - L1_hit_rate) * L2_hit_rate_given_L1_miss
count_DRAM = count_total - count_L1 - count_L2
```

The exact Nsight Compute metrics must be recorded in the run log because metric names differ across CUDA/NCU releases.

## Static Mismatch Risk

Wattchmen notes that training microbenchmarks run with all SMs active, while full applications may not. V1 accepts this risk and uses the full-activity static term for both training and first operator prediction.

This assumption is likely wrong for operators with:

- low occupancy,
- bursty short kernels,
- partial-SM execution,
- long host gaps between kernels,
- large static/constant fraction relative to dynamic energy.

Do not silently tune `P_static` to make one operator pass. If this mismatch dominates, record it in `QUALITY.md` and create an execution plan for an activity-aware model.

## When To Request Human Modeling Review

Main Agent should request review instead of only adding microbenchmarks when:

- Phase 3 residual is low but Phase 4 operator error remains above 15%,
- SASS coverage is high but error is still high,
- error correlates with low occupancy or low active-SM behavior,
- measured operator energy is dominated by constant/static terms,
- tensor/WGMMA/TMA/barrier instructions are covered but tensor operators remain biased,
- power repeatability passes but prediction bias is stable across repeats,
- changing buckets or scaling rules improves one operator and degrades another.

## V2 Candidate Changes

Future execution plans may evaluate:

- active-SM or occupancy-aware static scaling,
- separate static baselines for memory-bound and tensor-bound active-no-op kernels,
- explicit host-gap and multi-kernel operator aggregation policy,
- WGMMA/TMA/barrier-specific pipeline grouping,
- temperature correction after repeatability is otherwise stable,
- separate width/hit-level scaling for global/shared/local memory instructions.

Any V2 change must be introduced through `docs/exec-plans/<xx+1>-plan.md`, evaluated as a full `xx-exp`, and recorded in `QUALITY.md`.
