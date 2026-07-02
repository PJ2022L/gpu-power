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
