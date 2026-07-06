# Experiments

H800 agents should write experiment outputs here.

## Layout

- `raw/`: raw power traces, NCU reports, Nsys reports, SASS dumps.
- `processed/`: parsed CSV/JSON/YAML artifacts, matrices, normalized tables.
- `reports/`: phase reports and validation summaries.
- `figures/`: generated figures and plotting scripts.
- `logs/`: command logs, environment logs, metadata.

## Rule

Every experiment command must write a log under `experiments/logs/` with:

- command,
- config path,
- hyperparameters,
- GPU ID and UUID,
- driver/CUDA/NCU/Nsys versions,
- clock and power limit state,
- output artifact paths.

## Required Raw Subdirectories

- `raw/operator_profiles/`: Phase 03-05 NCU/Nsys operator profiling artifacts.
- `raw/microbench_power/`: Phase 08 non-profiled microbenchmark power traces.
- `raw/operator_power/`: Phase 11 non-profiled operator power ground truth.
- `static_power/raw/`: Phase 02 static + constant baseline traces.
- `dynamic_power/iter_<N>/`: dynamic power iteration artifacts.
- `e2e_testset/raw/`: E2E operator power ground truth and profiler artifacts.
- `environment/<timestamp>/`: H800 environment evidence packages.

For `raw/operator_power/`, use:

```text
experiments/raw/operator_power/<operator>/<shape_id>/
  metadata.yaml
  power_trace.csv
  summary.yaml
  repeatability.yaml
```

The same file set is used for `raw/microbench_power/<bench_id>/`.

Baseline runs use:

```text
experiments/static_power/raw/<baseline_id>/
  metadata.yaml
  power_trace.csv
  summary.yaml
  repeatability.yaml
```

Dynamic power iterations use:

```text
experiments/dynamic_power/iter_<N>/
  raw/microbench_power/
  raw/sass/
  raw/ncu/
  processed/
  sass_counts.csv
  ncu_metrics.csv
  model_coefficients.csv
  fit_report.md
  pred_vs_measured.csv
```
