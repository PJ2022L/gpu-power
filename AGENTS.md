# AGENTS.md

## Project Rule

This repository is a staged H800 Wattchmen reproduction project. The final target is SASS-class power modeling and operator-level power prediction for GEMM, FlashMLA, and FlashAttention v3.

## Environment

- H800 experiments run in Docker container `operatorsforge:h800-v1.0` with container name `l2_mla_study`.
- Do not run H800 experiments on a non-H800 server.
- If using Python, run `conda activate vla`.
- Shell scripts must print the exact command and hyperparameters to log files.
- Plotting scripts belong in the corresponding figure directory.

## Agent Responsibilities

- Main Agent: owns global plan, phase gates, `QUALITY.md`, and next experiment plan creation.
- Operator SASS Agent: profiles operators and reports kernels, SASS top-k, and memory/cache behavior.
- Microbench Agent: designs/runs SASS-class microbenchmarks and records power/profiling artifacts.
- Modeling Agent: fits const/static/dynamic model and SASS energy table.
- Validation Agent: predicts operator power and reports measured-vs-predicted error.

Quality tracking is part of Main Agent. Main Agent updates `QUALITY.md` after every complete experiment loop.

## Required Documents

- Top-level map: `ARCHITECTURE.md`
- Knowledge index: `knowledge/README.md`
- Roadmap: `docs/roadmap.md`
- Agent handoff: `docs/agents/handoff_contracts.md`
- Power measurement environment: `docs/design-spec/power_measurement_environment.md`
- Quality ledger: `QUALITY.md`
- Per-experiment plans: `docs/exec-plans/xx-plan.md`

## Experiment Definition

A complete experiment is:

```text
micro-benchmark -> calibration/model fitting -> operator test
```

Record it as `xx-exp` in `QUALITY.md`.

After analyzing `xx-exp`, create the next execution plan as `docs/exec-plans/<next>-plan.md`.

## Measurement Discipline

Before trusting power results, confirm:

- target GPU is isolated,
- clocks are locked or fully recorded,
- power limit is fixed or fully recorded,
- no unrelated GPU process is running,
- thermal throttling and power throttling are absent or recorded,
- NVML/NCU/Nsys/CUDA versions are logged,
- profiler runs and power runs are separate.
