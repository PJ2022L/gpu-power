# QUALITY

This document tracks whether the repository and model are getting stronger or weaker over time.

An experiment is defined as one complete loop:

```text
micro-benchmark -> calibration/model fitting -> operator test
```

Each experiment must be numbered as `xx-exp`, for example `01-exp`, `02-exp`, `03-exp`.

Plan and experiment numbering is one-to-one:

```text
01-plan.md -> 01-exp -> 02-plan.md
```

`xx-plan.md` is the plan that produced `xx-exp`. After analyzing `xx-exp`, Main Agent writes `<xx+1>-plan.md`.

## Current Status

| Field | Value |
| --- | --- |
| Current best experiment | TBD |
| Current best mean operator error | TBD |
| Current best max operator error | TBD |
| Target error | <= 15% |
| Current decision | No completed H800 experiment yet |

## Experiment Ledger

| Exp ID | Date | Micro-benchmarks | Model Adjustments | Operator Test Set | Mean Error | Max Error | Decision | Next Guidance |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 00-exp | TBD | None | None | None | N/A | N/A | baseline skeleton | Run Phase 1 operator profiling on H800 |

## Experiment Detail Template

Copy this section for every completed experiment.

### xx-exp: short title

| Field | Value |
| --- | --- |
| Date | YYYY-MM-DD |
| Agent | TBD |
| Container | `operatorsforge:h800-v1.0` / `l2_mla_study` |
| Git commit | TBD |
| H800 GPU UUID | TBD |
| Driver/CUDA/NCU versions | TBD |
| Configs | TBD |
| Reports | TBD |
| Plan that produced this experiment | `docs/exec-plans/xx-plan.md` |
| Next plan | `docs/exec-plans/<xx+1>-plan.md` |

#### 1. Micro-benchmarks

List what was added or rerun:

| Benchmark | Target SASS class | Status | Notes |
| --- | --- | --- | --- |
| TBD | TBD | planned / valid / invalid | TBD |

#### 2. Model Adjustments

Describe changes to the model:

- const/static handling:
- dynamic solve:
- grouping:
- scaling:
- bucketing:
- removed components:
- added components:

#### 3. Problems And Next Guidance

Describe what went wrong and how the next experiment should respond:

- missing SASS coverage:
- unstable microbenchmarks:
- high residuals:
- operator-specific mismatch:
- measurement noise:
- required human intervention:

#### 4. Error

| Operator | Measured Power | Predicted Power | Error | Notes |
| --- | --- | --- | --- | --- |
| GEMM | TBD | TBD | TBD | TBD |
| FlashMLA | TBD | TBD | TBD | TBD |
| FlashAttention v3 | TBD | TBD | TBD | TBD |

## Simplified Experiment Log

Use this table for quick ablation or component-removal decisions.

| 日期 | 移除的组件 | 结果 | 决策 |
| --- | --- | --- | --- |
| YYYY-MM-DD | [component] | [degraded / unchanged] | [restore / keep removed] |

## Quality Rules

- An experiment is only valid if it includes microbenchmark results, calibration/model fitting, and operator testing.
- If an experiment changes only one stage, record it as a partial note in the relevant phase report, not as a new `xx-exp`.
- The Main Agent updates this file after Phase 4 or Phase 5.
- Main Agent uses this file to decide whether the repository is improving.
- If mean error improves but max operator error gets worse, mark the decision as `mixed`.
- If error improves by removing a component, record the component in the simplified log and justify whether to keep it removed.

## Next Experiment Plan

After analyzing a completed `xx-exp`, Main Agent must write the next plan to:

```text
docs/exec-plans/<xx+1>-plan.md
```

For example, `01-plan.md` produces `01-exp`; after `01-exp` is analyzed, Main Agent writes `02-plan.md`.

The plan should explain whether the next step is adding microbenchmarks, changing calibration/modeling, collecting more operator profiles, or requesting human intervention.
