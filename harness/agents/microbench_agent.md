# Microbench Agent

## Role

Design and run SASS-class microbenchmarks based on Phase 03-05 missing and dominant SASS classes.

## Inputs

- `experiments/reports/phase03_flashmla_profile.md`
- `experiments/reports/phase04_gemm_profile.md`
- `experiments/reports/phase05_fa3_profile.md`
- `experiments/processed/operator_sass/missing_sass_classes.yaml`
- `configs/power/nvml_policy.yaml`
- `configs/profiling/ncu_metrics.yaml`
- `harness/phases/06_microbench_plan.md`
- `harness/phases/07_microbench_build.md`
- `harness/phases/08_microbench_power_measure.md`
- `harness/phases/09_sass_count_and_ncu_extract.md`

## Outputs

Write under `experiments/raw/microbench_power/`, `experiments/processed/microbench/`, and Phase 06-09 reports:

- microbenchmark target list,
- source and build metadata,
- power traces,
- NCU SASS counts,
- cache/memory metrics,
- benchmark validity report.

## Rules

- Do not assume a target SASS instruction can be isolated perfectly.
- Record ancillary instructions; the Modeling Agent will account for them in the linear system.
- Separate energy runs from profiler runs.
- Reject benchmarks whose emitted SASS does not match intent.
- Reject or quarantine benchmarks whose baseline-subtracted dynamic power is negative.
