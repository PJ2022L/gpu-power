# Agent Handoff Contracts

## Global Rules

Each phase handoff must include:

- exact command,
- config file path,
- git commit if available,
- runtime session identity,
- GPU ID and UUID,
- driver/CUDA/NCU/Nsys versions,
- clock and power limit state,
- output artifact paths,
- known failures or caveats.

## Phase 03-05 To Phase 06

Required artifact:

```text
experiments/processed/operator_sass/missing_sass_classes.yaml
experiments/reports/phase03_flashmla_profile.md
experiments/reports/phase04_gemm_profile.md
experiments/reports/phase05_fa3_profile.md
```

Phase 03-05 artifacts are profiling artifacts only. They must not include or require `experiments/raw/operator_power/` as validation ground truth.

Required content:

- operator name,
- kernel name,
- shape/dtype,
- SASS top-k,
- memory/cache metrics,
- target SASS classes for microbenchmarking.
- profile-only statement: operator power ground truth will be collected in Phase 11.

## Phase 06-09 To Phase 10

Required artifact:

```text
experiments/raw/microbench_power/<bench_id>/metadata.yaml
experiments/raw/microbench_power/<bench_id>/power_trace.csv
experiments/raw/microbench_power/<bench_id>/summary.yaml
experiments/raw/microbench_power/<bench_id>/repeatability.yaml
experiments/processed/microbench/microbench_matrix_inputs.*
experiments/reports/phase06_microbench_plan.md
experiments/reports/phase07_microbench_build.md
experiments/reports/phase08_microbench_power.md
experiments/reports/phase09_sass_count_and_ncu_extract.md
```

The raw `microbench_power` artifacts are produced by `src/power/nvml_sampler.py`. The processed `microbench_matrix_inputs.*` artifact is a Phase 09 post-processing deliverable: it must combine raw power summaries, SASS opcode counts, cache metrics, emitted-SASS verification, and launch metadata into the matrix/vector inputs consumed by Phase 10.

Until that post-processing exists, Phase 06-09 may not be accepted as complete for model fitting; it can only be marked as raw-data collection complete.

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
- negative dynamic power quarantine flag if baseline-subtracted power is below zero.

## Phase 02 And Phase 10 To Phase 11

Required artifact:

```text
experiments/static_power/raw/
experiments/static_power/processed/static_power_samples.csv
experiments/processed/modeling/sass_energy_table.*
experiments/reports/phase10_dynamic_model_fit.md
```

Required content:

- idle baseline ID and active-no-op baseline ID,
- const/static estimate,
- SASS class energy,
- estimate source label,
- residuals,
- coverage report.
- non-negative RHS/coefficient/prediction checks.

## Phase 11-12 To Phase 13

Required artifact:

```text
experiments/raw/operator_power/
experiments/reports/phase11_e2e_power_ground_truth.md
experiments/reports/phase12_e2e_prediction_validation.md
```

Required content:

- operator power metadata, trace, and repeatability artifact paths,
- operator power summary artifact paths,
- measured vs predicted power,
- error percentage,
- operator power repeatability report,
- missing/bucketed energy fraction,
- non-negative measured/predicted power checks,
- recommendation: accept, expand microbenchmarks, or human intervention.

## Phase 12/13 To Main Agent Quality Update

Required artifact:

```text
QUALITY.md
experiments/reports/phase08_microbench_power.md
experiments/reports/phase09_sass_count_and_ncu_extract.md
experiments/reports/phase10_dynamic_model_fit.md
experiments/reports/phase12_e2e_prediction_validation.md
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
- plan that produced this experiment, e.g. `harness/exec-plans/01-plan.md` for `01-exp`.
- next execution plan path, e.g. `harness/exec-plans/02-plan.md` after `01-exp`.
