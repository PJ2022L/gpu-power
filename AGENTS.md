# AGENTS.md

## Project Rule

This repository is a staged H800 Wattchmen reproduction project. The final target is SASS-class power modeling and operator-level power prediction for GEMM, FlashMLA, and FlashAttention v3, with target MSAE below 15%.

## Research Integrity

- Do not invent paths, paper conclusions, benchmark capabilities, tool outputs, or experiment results.
- Every technical conclusion must be traceable to a source: paper, repository code, official documentation, experiment log, profiler report, or benchmark output.
- If a path does not exist, search nearby directories and update `.agents/knowledge/ROUTE_MAP.md` instead of assuming the old route is valid.
- Do not mix latency profiling with power modeling. Nsight Compute/Nsight Systems profiling artifacts are not power ground truth.
- All short kernels must be loop-amplified before power measurement.
- Every benchmark run must record SASS, runtime parameters, power trace, runtime, and Nsight counters.
- All experiments must save raw data, exact command, hyperparameters, environment information, and git commit.
- The final model must explicitly explain constant/idle power, active static power, and dynamic SASS instruction-level power.
- H800 is the current priority target. Directory design and route maps should remain compatible with later H100/B200 additions.
- Power and energy values must not be silently negative. Negative measured power, negative baseline-subtracted dynamic power, negative fitted SASS coefficients, and negative predictions are invalid for accepted model artifacts unless quarantined with a diagnostic reason.

## Environment

- H800 experiments run from the already-provided H800 runtime session.
- Do not run H800 experiments on a non-H800 server.
- Python runs with the runtime session's default `python`; do not assume a separate environment activation step.
- NVML sampling requires Python package `pynvml` from `nvidia-ml-py`.
- Shell scripts must print the exact command and hyperparameters to log files.
- Plotting scripts belong in the corresponding figure directory.

## Runtime Safety

- Do not start, stop, rebuild, remove, prune, or reconfigure the surrounding runtime from this repository.
- Do not run destructive filesystem commands outside this repository, especially under `/`, `/data1`, mounted datasets, `.agents/library/`, or existing `experiments/raw/` data.
- Do not remove raw traces, profiler reports, source library files, or previous experiment logs unless the user explicitly asks for that exact cleanup.
- Do not kill unrelated GPU processes. If another process is using the target GPU, mark the run invalid or ask for operator action.
- Do not change clocks, power limits, persistence mode, MIG, ECC, driver settings, CUDA installation, or device files except through an approved phase protocol that logs the exact command and result.
- Do not install or upgrade system packages, CUDA components, drivers, or global Python packages as part of an experiment. Record missing dependencies in the phase report instead.
- Do not write build artifacts, temporary downloads, or generated data into `.agents/library/`; use the phase-defined build/output directory.
- Do not print secrets, tokens, private environment variables, or host credentials into logs.
- Do not overwrite output directories in place. Use timestamped or experiment-ID paths and preserve raw data.

## Agent Responsibilities

- Main Agent: owns global plan, phase gates, `QUALITY.md`, and next experiment plan creation.
- Operator SASS Agent: profiles operators and reports kernels, SASS top-k, and memory/cache behavior; does not collect validation power ground truth.
- Microbench Agent: designs/runs SASS-class microbenchmarks and records power/profiling artifacts.
- Modeling Agent: fits const/static/dynamic model and SASS energy table.
- Validation Agent: collects Phase 11 non-profiled operator power ground truth, predicts operator power in Phase 12, and reports measured-vs-predicted error.

Quality tracking is part of Main Agent. Main Agent updates `QUALITY.md` after every complete experiment loop.

## Required Documents

- Top-level map: `ARCHITECTURE.md`
- Knowledge route map: `.agents/knowledge/ROUTE_MAP.md`
- Knowledge index: `.agents/knowledge/INDEX.md`
- Source inventory: `.agents/knowledge/SOURCE_INVENTORY.md`
- Roadmap: `harness/roadmap.md`
- Agent handoff: `harness/agents/handoff_contracts.md`
- Power measurement environment: `harness/design-spec/power_measurement_environment.md`
- Metrics definition: `.agents/knowledge/METRICS.md`
- H800 environment protocol: `.agents/knowledge/H800_ENVIRONMENT_PROTOCOL.md`
- Static baseline model: `.agents/knowledge/STATIC_POWER_MODEL.md`
- Dynamic power model: `.agents/knowledge/DYNAMIC_POWER_MODEL.md`
- SASS category map: `.agents/knowledge/SASS_CATEGORY_MAP.md`
- Quality ledger: `QUALITY.md`
- Per-experiment plans: `harness/exec-plans/xx-plan.md`

## Key References

The primary methodology reference is Wattchmen:

- **Canonical knowledge base**: `.agents/knowledge/` — H800-focused paper notes, modeling methods, microbenchmark catalog, measurement protocol, and platform context.
- **Original Wattchmen paper**: `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf` — the primary source; read before designing any microbenchmark or solver.

For microbenchmark construction, start from two entry points:

1. **`.agents/library/benchmarks/accelwattch-ubench/`** — AccelWattch has public CUDA microbenchmarks. Borrow engineering patterns, but do NOT copy its V100 component-level power table; H800 must train its own SASS energy table.
2. **`.agents/library/papers/wattchmen/` and `.agents/knowledge/POWER_MODELING_METHODS.md`** — Wattchmen defines the correct modeling abstraction: treat all microbenchmarks together as a linear system `A x = b`, do not try to isolate single instructions perfectly.

## Phase Routing

Use `harness/phases/00_route_and_environment.md` through `harness/phases/13_error_review_next_iteration.md` as the executable phase gates. The previous coarse phase split has been replaced by these smaller phases.

## Experiment Definition

A complete experiment is:

```text
micro-benchmark -> calibration/model fitting -> operator test
```

Record it as `xx-exp` in `QUALITY.md`.

`xx-plan.md` is the plan that produces `xx-exp`. After analyzing `xx-exp`, create the next execution plan as `harness/exec-plans/<xx+1>-plan.md`.

## Measurement Discipline

Before trusting power results, confirm:

- target GPU is isolated,
- clocks are locked or fully recorded,
- power limit is fixed or fully recorded,
- no unrelated GPU process is running,
- thermal throttling and power throttling are absent or recorded,
- NVML/NCU/Nsys/CUDA versions are logged,
- profiler runs and power runs are separate,
- repeated-run CV and temperature/clock drift pass `harness/design-spec/power_measurement_environment.md`.
