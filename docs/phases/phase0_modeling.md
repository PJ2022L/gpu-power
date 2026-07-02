# Phase 0: Wattchmen Modeling Understanding

## Goal

Lock the modeling interpretation before experiments:

```text
E_total = E_const + E_static + E_dynamic
```

Dynamic energy is fitted from SASS counts and microbenchmark energy measurements.

## Inputs

- `knowledge/00-reference_essay/wattchmen/01-paper-summary.md`
- `knowledge/00-reference_essay/wattchmen/02-modeling-method.md`
- `knowledge/00-reference_essay/wattchmen/03-microbenchmark-design.md`
- `knowledge/00-reference_essay/wattchmen/04-measurement-protocol.md`

## Outputs

- `experiments/reports/phase0_modeling_checklist.md`

## Acceptance Criteria

- Agent can explain const/static/dynamic separation.
- Agent can explain why ancillary instructions are handled by a linear system.
- Agent can explain why profiling and power measurement are separate runs.
- Agent can explain the 15% operator validation target.
