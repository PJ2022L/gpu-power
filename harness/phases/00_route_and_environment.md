# Phase 00: Route And Environment

## Goal

Confirm that the H800 agent is using the current repository routes and can collect the required environment package before any profiling or power measurement.

## Owner

Main Agent.

## Inputs

- `ARCHITECTURE.md`
- `AGENTS.md`
- `.agents/knowledge/ROUTE_MAP.md`
- `.agents/knowledge/INDEX.md`
- `configs/power/nvml_policy.yaml`

## Commands

```bash
scripts/00_check_env.sh
scripts/00_collect_h800_environment.sh configs/power/nvml_policy.yaml
```

## Outputs

- `experiments/environment/`
- `experiments/logs/00_check_env_*.log`
- `experiments/logs/00_collect_h800_environment_*.log`
- `experiments/reports/phase00_route_and_environment.md`

## Acceptance Criteria

- Current canonical routes are confirmed: `.agents/library/`, `.agents/knowledge/`, `harness/`, and `experiments/`.
- Runtime session identity is recorded.
- GPU model, UUID, driver, CUDA, NCU, Nsys, clock, power limit, temperature, and process state are logged.
- The target GPU is isolated or the run is marked invalid/exploratory.
- No H800 experiment starts before this phase is accepted.

## Failure Handling

If a configured path is missing, search nearby directories, update `.agents/knowledge/ROUTE_MAP.md`, and stop before running measurements.
