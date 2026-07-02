# Phase 2: Microbenchmark Design And Measurement

## Goal

Build microbenchmarks for SASS classes identified in Phase 1 and measure their energy behavior on H800.

## Owner

Microbench Agent.

## Inputs

- `experiments/processed/operator_sass/missing_sass_classes.yaml`
- `configs/power/nvml_policy.yaml`
- `configs/profiling/ncu_metrics.yaml`

## Commands

```bash
scripts/02_plan_microbenchmarks.sh experiments/processed/operator_sass/missing_sass_classes.yaml
scripts/03_run_microbenchmarks.sh configs/power/nvml_policy.yaml
```

Energy-mode runs must use `src/power/nvml_sampler.py` or a wrapper around it. Profiler-mode NCU runs remain separate.

## Outputs

- `experiments/raw/microbench_power/`
- `experiments/processed/microbench/`
- `experiments/reports/phase2_microbench_report.md`

## Acceptance Criteria

- Each target SASS class has a benchmark plan.
- Each completed benchmark has power trace, SASS count, and cache metric artifacts.
- Energy runs and profiler runs are separate.
- Repeatability report passes thresholds in `docs/design-spec/power_measurement_environment.md`.
- Invalid benchmarks are explicitly flagged.

## Failure Handling

If a SASS class cannot be directly benchmarked, mark it for grouping, scaling, or bucketing and explain the reason.
