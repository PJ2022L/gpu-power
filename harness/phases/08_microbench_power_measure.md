# Phase 08: Microbenchmark Power Measurement

## Goal

Collect repeatable non-profiled NVML power traces for built microbenchmarks.

## Owner

Microbench Agent.

## Inputs

- `experiments/processed/microbench/build_manifest.yaml`
- `configs/power/nvml_policy.yaml`
- `harness/design-spec/power_measurement_environment.md`

## Commands

```bash
scripts/03_run_microbenchmarks.sh configs/power/nvml_policy.yaml --power-only
```

If the current placeholder script does not yet support `--power-only`, the H800 agent must implement that mode before accepting this phase.

## Outputs

- `experiments/raw/microbench_power/<bench_id>/metadata.yaml`
- `experiments/raw/microbench_power/<bench_id>/power_trace.csv`
- `experiments/raw/microbench_power/<bench_id>/summary.yaml`
- `experiments/raw/microbench_power/<bench_id>/repeatability.yaml`
- `experiments/reports/phase08_microbench_power.md`

## Acceptance Criteria

- Each accepted benchmark has enough loop amplification to create a stable active window.
- Power runs are not NCU/Nsys runs.
- Repeatability thresholds pass.
- Measured active-window power and energy are non-negative.
- Any benchmark whose baseline-subtracted dynamic power would be negative is marked invalid for fitting.

## Failure Handling

If repeatability fails, rerun after checking process isolation, clocks, power limit, temperature, loop length, and saturation. Do not move unstable data into the fitting matrix.
