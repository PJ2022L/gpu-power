# Phase 11: E2E Operator Power Ground Truth

## Goal

Collect non-profiled operator power ground truth for the exact GEMM, FlashMLA, and FlashAttention v3 shapes used for validation.

## Owner

Validation Agent.

## Inputs

- `configs/operators/gemm.yaml`
- `configs/operators/flashmla.yaml`
- `configs/operators/flashattention_v3.yaml`
- `configs/power/nvml_policy.yaml`
- `harness/design-spec/power_measurement_environment.md`

## Commands

```bash
scripts/05_collect_operator_power.sh configs/operators/gemm.yaml configs/power/nvml_policy.yaml
scripts/05_collect_operator_power.sh configs/operators/flashmla.yaml configs/power/nvml_policy.yaml
scripts/05_collect_operator_power.sh configs/operators/flashattention_v3.yaml configs/power/nvml_policy.yaml
```

## Outputs

- `experiments/raw/operator_power/<operator>/<shape_id>/metadata.yaml`
- `experiments/raw/operator_power/<operator>/<shape_id>/power_trace.csv`
- `experiments/raw/operator_power/<operator>/<shape_id>/summary.yaml`
- `experiments/raw/operator_power/<operator>/<shape_id>/repeatability.yaml`
- `experiments/reports/phase11_e2e_power_ground_truth.md`

## Acceptance Criteria

- Operator power runs are not NCU/Nsys runs.
- Commands, shapes, warmup, repeats, GPU ID, clocks, power limit, versions, and commit are logged.
- Short operators are loop-amplified until the active window is stable.
- Repeatability thresholds pass.
- Measured active-window power, dynamic power, and energy are non-negative.

## Failure Handling

If an operator cannot produce stable ground truth, exclude it from MSAE only with an explicit phase report reason and next-plan action.
