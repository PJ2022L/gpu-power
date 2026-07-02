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

- `raw/operator_profiles/`: Phase 1 NCU/Nsys operator profiling artifacts.
- `raw/baseline_power/`: idle and active-no-op baseline power traces for `P_const` and `P_static`.
- `raw/microbench_power/`: Phase 2 non-profiled microbenchmark power traces.
- `raw/operator_power/`: Phase 4 non-profiled operator power ground truth.

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
experiments/raw/baseline_power/<baseline_id>/
  metadata.yaml
  power_trace.csv
  summary.yaml
  repeatability.yaml
```
