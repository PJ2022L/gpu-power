# Agent Handoff Contracts

## Global Rules

Each phase handoff must include:

- exact command,
- config file path,
- git commit if available,
- container image and name,
- GPU ID and UUID,
- driver/CUDA/NCU/Nsys versions,
- clock and power limit state,
- output artifact paths,
- known failures or caveats.

## Phase 1 To Phase 2

Required artifact:

```text
experiments/processed/operator_sass/missing_sass_classes.yaml
experiments/reports/phase1_operator_sass_report.md
```

Phase 1 artifacts are profiling artifacts only. They must not include or require `experiments/raw/operator_power/` as validation ground truth.

Required content:

- operator name,
- kernel name,
- shape/dtype,
- SASS top-k,
- memory/cache metrics,
- target SASS classes for microbenchmarking.
- profile-only statement: operator power ground truth will be collected in Phase 4.

## Phase 2 To Phase 3

Required artifact:

```text
experiments/raw/microbench_power/<bench_id>/metadata.yaml
experiments/raw/microbench_power/<bench_id>/power_trace.csv
experiments/raw/microbench_power/<bench_id>/summary.yaml
experiments/raw/microbench_power/<bench_id>/repeatability.yaml
experiments/processed/microbench/microbench_matrix_inputs.*
experiments/reports/phase2_microbench_report.md
```

The raw `microbench_power` artifacts are produced by `src/power/nvml_sampler.py`. The processed `microbench_matrix_inputs.*` artifact is a Phase 2 post-processing deliverable: it must combine raw power summaries, SASS opcode counts, cache metrics, emitted-SASS verification, and launch metadata into the matrix/vector inputs consumed by Phase 3.

Until that post-processing exists, Phase 2 may not be accepted as complete for model fitting; it can only be marked as raw-data collection complete.

Required content:

- benchmark name,
- target SASS class,
- emitted SASS verification,
- power trace path,
- power summary path,
- repeatability report path,
- SASS count path,
- cache metric path,
- validity flag.

## Phase 3 To Phase 4

Required artifact:

```text
experiments/raw/baseline_power/
experiments/processed/modeling/sass_energy_table.*
experiments/reports/phase3_model_report.md
```

Required content:

- idle baseline ID and active-no-op baseline ID,
- const/static estimate,
- SASS class energy,
- estimate source label,
- residuals,
- coverage report.

## Phase 4 To Phase 5

Required artifact:

```text
experiments/raw/operator_power/
experiments/reports/phase4_operator_power_report.md
experiments/reports/phase4_validation_report.md
```

Required content:

- operator power metadata, trace, and repeatability artifact paths,
- operator power summary artifact paths,
- measured vs predicted power,
- error percentage,
- operator power repeatability report,
- missing/bucketed energy fraction,
- recommendation: accept, expand microbenchmarks, or human intervention.

## Phase 4/5 To Main Agent Quality Update

Required artifact:

```text
QUALITY.md
experiments/reports/phase2_microbench_report.md
experiments/reports/phase3_model_report.md
experiments/reports/phase4_validation_report.md
```

Required content for a complete `xx-exp` entry:

- experiment ID,
- date,
- microbenchmarks added or rerun,
- model adjustments,
- measured vs predicted operator power,
- mean and max error,
- problems,
- next-experiment guidance,
- simplified ablation row if any component was removed.
- plan that produced this experiment, e.g. `docs/exec-plans/01-plan.md` for `01-exp`.
- next execution plan path, e.g. `docs/exec-plans/02-plan.md` after `01-exp`.
