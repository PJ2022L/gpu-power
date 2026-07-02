# AGENTS.md

## Project Rule

This repository is a staged H800 Wattchmen reproduction project. The final target is SASS-class power modeling and operator-level power prediction for GEMM, FlashMLA, and FlashAttention v3.

## Environment

- H800 experiments run in Docker container `operatorsforge:h800-v1.0` with container name `l2_mla_study`.
- Do not run H800 experiments on a non-H800 server.
- Python runs with the Docker container's default `python`; do not assume a separate environment activation step.
- NVML sampling requires Python package `pynvml` from `nvidia-ml-py` inside the H800 container.
- Shell scripts must print the exact command and hyperparameters to log files.
- Plotting scripts belong in the corresponding figure directory.

## Agent Responsibilities

- Main Agent: owns global plan, phase gates, `QUALITY.md`, and next experiment plan creation.
- Operator SASS Agent: profiles operators and reports kernels, SASS top-k, and memory/cache behavior; does not collect validation power ground truth.
- Microbench Agent: designs/runs SASS-class microbenchmarks and records power/profiling artifacts.
- Modeling Agent: fits const/static/dynamic model and SASS energy table.
- Validation Agent: collects Phase 4 non-profiled operator power ground truth, predicts operator power, and reports measured-vs-predicted error.

Quality tracking is part of Main Agent. Main Agent updates `QUALITY.md` after every complete experiment loop.

## Required Documents

- Top-level map: `ARCHITECTURE.md`
- Knowledge index: `knowledge/README.md`
- Roadmap: `docs/roadmap.md`
- Agent handoff: `docs/agents/handoff_contracts.md`
- Power measurement environment: `docs/design-spec/power_measurement_environment.md`
- Quality ledger: `QUALITY.md`
- Per-experiment plans: `docs/exec-plans/xx-plan.md`

## Key References

The primary methodology reference is Wattchmen:

- **Wattchmen methodology**: `knowledge/00-reference_essay/wattchmen/` — paper summary, modeling method, microbenchmark design, and measurement protocol.
- **Original paper**: `knowledge/library/PDF/essay/Wattchmen-Watching the Wattchers.pdf` — the primary source; read before designing any microbenchmark or solver.

For microbenchmark construction, start from two entry points:

1. **`knowledge/00-reference_essay/accelwattch/`** — AccelWattch has public source code (CUDA microbenchmarks, NVML measurement harness, profiling scripts). Borrow engineering patterns (benchmark structure, measurement loop, GPU isolation) but do NOT copy its V100 component-level power table — H800 must train its own SASS energy table.
2. **`knowledge/00-reference_essay/wattchmen/`** — Wattchmen defines the correct modeling abstraction: treat all microbenchmarks together as a linear system `A x = b`, do not try to isolate single instructions perfectly.

## Experiment Definition

A complete experiment is:

```text
micro-benchmark -> calibration/model fitting -> operator test
```

Record it as `xx-exp` in `QUALITY.md`.

`xx-plan.md` is the plan that produces `xx-exp`. After analyzing `xx-exp`, create the next execution plan as `docs/exec-plans/<xx+1>-plan.md`.

## Measurement Discipline

Before trusting power results, confirm:

- target GPU is isolated,
- clocks are locked or fully recorded,
- power limit is fixed or fully recorded,
- no unrelated GPU process is running,
- thermal throttling and power throttling are absent or recorded,
- NVML/NCU/Nsys/CUDA versions are logged,
- profiler runs and power runs are separate,
- repeated-run CV and temperature/clock drift pass `docs/design-spec/power_measurement_environment.md`.
