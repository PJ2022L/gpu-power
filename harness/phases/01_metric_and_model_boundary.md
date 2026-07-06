# Phase 01: Metric And Model Boundary

## Goal

Lock the metric definition and the first Wattchmen-style H800 model boundary.

## Owner

Main Agent with Modeling Agent review.

## Inputs

- `.agents/knowledge/POWER_MODELING_METHODS.md`
- `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`
- `.agents/knowledge/METRICS.md`
- `.agents/knowledge/STATIC_POWER_MODEL.md`
- `.agents/knowledge/DYNAMIC_POWER_MODEL.md`
- `harness/design-spec/modeling.md`
- `harness/design-spec/power_measurement_environment.md`

## Commands

No GPU command is required. This is a documentation and gate-check phase.

## Outputs

- `experiments/reports/phase01_metric_and_model_boundary.md`

## Acceptance Criteria

- Primary metric is confirmed as `MSAE = mean(|P_pred - P_meas| / P_meas) * 100%`.
- `P_meas` is defined as non-profiled active-window average power.
- `P_const`, `P_static`, and `P_dynamic` boundaries are documented.
- Non-negative power constraints are accepted:
  - measured power and energy must be non-negative,
  - `P_const >= 0`,
  - `P_static >= 0`,
  - `P_dynamic = P_meas - P_const_static >= 0`,
  - fitted SASS energy coefficients must be non-negative,
  - predictions must not emit negative dynamic or total power.
- Phase 03-05 profiling is explicitly separated from Phase 11 operator power ground truth.

## Failure Handling

If the team cannot agree on the model boundary, stop and request human review before collecting training data.
