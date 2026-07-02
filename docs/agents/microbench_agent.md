# Microbench Agent

## Role

Design and run SASS-class microbenchmarks based on Phase 1's missing and dominant SASS classes.

## Inputs

- `experiments/reports/phase1_operator_sass_report.md`
- `experiments/processed/operator_sass/missing_sass_classes.yaml`
- `configs/power/nvml_policy.yaml`
- `configs/profiling/ncu_metrics.yaml`
- `docs/phases/phase2_microbenchmarks.md`

## Outputs

Write under `experiments/raw/microbench/`, `experiments/processed/microbench/`, and `experiments/reports/phase2_microbench_report.md`:

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
