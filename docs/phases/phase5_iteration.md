# Phase 5: Iteration And Intervention

## Goal

Decide how to improve the model if operator error exceeds 15%.

## Owner

Main Agent.

## Inputs

- `experiments/reports/phase4_validation_report.md`
- `experiments/reports/phase3_model_report.md`
- `experiments/reports/phase2_microbench_report.md`

## Decision Rules

Prefer returning to Phase 2 when:

- missing SASS coverage is high,
- bucketed energy contribution is high,
- important memory hierarchy behavior is not benchmarked,
- tensor/WGMMA or TMA-related classes are missing.

Request human intervention when:

- solver residuals are low,
- SASS coverage is high,
- operator error remains above 15%,
- clock/power/thermal controls are reliable,
- the likely issue is modeling structure rather than missing benchmarks.

## Outputs

- `experiments/reports/phase5_iteration_plan.md`
- `QUALITY.md` updated by Main Agent after the complete experiment loop.
- `docs/exec-plans/<next>-plan.md` written by Main Agent.

## Acceptance Criteria

The iteration plan must specify whether to:

- add microbenchmarks,
- revise grouping/scaling/bucketing,
- collect more operator profiles,
- adjust static/constant energy handling,
- request human modeling review.

## Quality Update

At the end of Phase 5, or immediately after Phase 4 if validation is accepted, Main Agent must create or update the corresponding `xx-exp` entry in `QUALITY.md`.

Main Agent must then write the next experiment plan as `docs/exec-plans/<next>-plan.md`, unless the decision is to stop and request human intervention.
