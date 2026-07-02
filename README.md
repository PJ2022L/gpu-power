# GPU Power: H800 Wattchmen Reproduction Skeleton

This repository is a staged, multi-agent skeleton for reproducing Wattchmen-style GPU power modeling on H800.

The final goal is to build a bottom-up model from SASS instruction classes to operator-level power for:

- GEMM
- FlashMLA
- FlashAttention v3

Target validation error is about 15% or lower against measured H800 operator power.

## Execution Environment

Experiments are not intended to run on the current server. They should run on an H800 server inside:

```text
image: operatorsforge:h800-v1.0
container name: l2_mla_study
```

The current repository provides:

- project skeleton,
- staged documentation,
- agent handoff contracts,
- configuration templates,
- script placeholders,
- output directory conventions.

The minimal power sampler is `src/power/nvml_sampler.py`. It uses the H800 Docker container's default `python` and requires the `pynvml` Python binding from `nvidia-ml-py`. Minimal Python dependencies are listed in `requirements-h800.txt`.

## Harness Philosophy

Harness is not a directory in this project. It is the experiment management method:

- every stage has explicit inputs and outputs,
- every agent has a bounded responsibility,
- every script logs command, hyperparameters, GPU state, and tool versions,
- artifacts flow through a fixed contract,
- validation gates decide whether the next phase can start.

## First Reading Path

1. `knowledge/README.md`
2. `ARCHITECTURE.md`
3. `docs/roadmap.md`
4. `docs/agents/main_agent.md`
5. `docs/agents/handoff_contracts.md`
6. `docs/phases/phase0_modeling.md`
7. `docs/design-spec/power_measurement_environment.md`
8. `configs/container.yaml`
9. `QUALITY.md`

## Stage Scripts

The stage scripts are placeholders for the H800 agent to complete:

```text
scripts/00_check_env.sh
scripts/01_profile_operators.sh
scripts/02_plan_microbenchmarks.sh
scripts/03_run_microbenchmarks.sh
scripts/04_fit_model.sh
scripts/05_collect_operator_power.sh
scripts/06_predict_operators.sh
scripts/07_validate_error.sh
scripts/collect_baselines.sh
```

Each script is intentionally conservative: it prints what it would do, writes a log, and points to the expected next artifact.

`collect_baselines.sh` is a support script used before Phase 3 fitting to collect idle and active-no-op power baselines for `P_const` and `P_static`; it is not a separate numbered phase.

## Quality Tracking

`QUALITY.md` tracks whether the model and repository are getting stronger or weaker. A valid experiment is one complete loop:

```text
micro-benchmark -> calibration/model fitting -> operator test
```

Each completed loop gets an ID such as `01-exp`. The Main Agent updates the ledger with microbenchmarks, model adjustments, problems, next guidance, and current error.

Plan numbering is fixed: `01-plan.md -> 01-exp -> 02-plan.md`. `xx-plan.md` is the plan that produces `xx-exp`; after analyzing `xx-exp`, Main Agent writes `docs/exec-plans/<xx+1>-plan.md`.

## Output Layout

H800 runs should write only under `experiments/`:

```text
experiments/
  raw/
  processed/
  reports/
  figures/
  logs/
```

Do not mix raw traces, parsed profiles, model outputs, and final reports.
