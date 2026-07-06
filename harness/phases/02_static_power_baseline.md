# Phase 02: Static And Constant Power Baseline

## Goal

Collect the baseline states needed to subtract constant and active static power before fitting dynamic SASS energy.

## Owner

Modeling Agent.

## Inputs

- `configs/power/nvml_policy.yaml`
- `harness/design-spec/modeling.md`
- `harness/design-spec/power_measurement_environment.md`
- `.agents/knowledge/STATIC_POWER_MODEL.md`

## Commands

```bash
GPU_ID=<gpu> scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml idle
GPU_ID=<gpu> scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml empty_kernel_active -- <empty-kernel-loop-command>
GPU_ID=<gpu> scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml low_activity_kernel -- <full-sm-low-switching-command>
```

## Outputs

- `experiments/static_power/raw/<baseline_id>/metadata.yaml`
- `experiments/static_power/raw/<baseline_id>/power_trace.csv`
- `experiments/static_power/raw/<baseline_id>/summary.yaml`
- `experiments/static_power/raw/<baseline_id>/repeatability.yaml`
- `experiments/static_power/processed/static_power_samples.csv`
- `experiments/reports/phase02_static_power_baseline.md`

## Acceptance Criteria

- Idle and at least one full-SM active baseline are collected with the same clock and power policy intended for later measurements.
- Baseline repeatability passes `harness/design-spec/power_measurement_environment.md`.
- `P_const >= 0` and `P_static = P_active_noop - P_const >= 0`.
- If `P_static < 0`, the baseline is invalid. Do not clamp it silently.
- Baseline IDs are ready for Phase 10 model fitting.

## Failure Handling

If baseline subtraction produces negative static power, rerun after checking GPU isolation, clocks, temperature drift, active-no-op saturation, and NVML trace alignment. If it persists, request modeling review.
