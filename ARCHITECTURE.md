# ARCHITECTURE

This is the top-level map for the H800 Wattchmen reproduction project. Keep this file short; use it for routing, not deep explanations.

## Goal

Build a staged system that measures SASS-class power on H800 and predicts operator power for GEMM, FlashMLA, and FlashAttention v3 with about 15% error or lower.

## Top-Level Structure

| Path | Purpose | Go deeper |
| --- | --- | --- |
| `knowledge/` | Research knowledge base: Wattchmen, hardware, tools, operators, original PDFs and repo links. | `knowledge/README.md` |
| `docs/agents/` | Multi-agent roles and handoff contracts. Main Agent owns global control and quality tracking. | `docs/agents/main_agent.md` |
| `docs/phases/` | Phase 0-5 execution workflow from modeling understanding to iteration. | `docs/roadmap.md` |
| `docs/design-spec/` | Design documents: modeling, calibration, measurement assumptions, and experimental design rationale. | `docs/design-spec/README.md` |
| `docs/exec-plans/` | Per-experiment plans named `xx-plan.md`, created after analyzing the previous `xx-exp`. | `docs/exec-plans/README.md` |
| `configs/` | YAML configuration templates for container, operators, profiling, power, and modeling. | `configs/container.yaml` |
| `scripts/` | Stage entrypoints and logging placeholders. | `scripts/00_check_env.sh` |
| `src/` | Future implementation placeholders for operators, microbenchmarks, profiling, power, and modeling. | `src/modeling/README.md` |
| `experiments/` | H800 run outputs: raw, processed, reports, figures, logs. | `experiments/README.md` |
| `QUALITY.md` | Quality ledger for completed `xx-exp` loops. | `QUALITY.md` |
| `AGENTS.md` | Repository operating instructions for agents. | `AGENTS.md` |

## Experiment Loop

```text
Phase 1 operator profiling
  -> Phase 2 micro-benchmark
  -> Phase 3 calibration/model fitting
  -> Phase 4 operator test
  -> QUALITY.md update
  -> docs/exec-plans/<next>-plan.md
```

If error is above target, Phase 5 decides whether to add microbenchmarks, adjust modeling, or request human intervention.

## Key Rules

- Experiments run on the H800 server, not on the current server.
- Target container: `operatorsforge:h800-v1.0`, name `l2_mla_study`.
- Power measurement must follow `docs/design-spec/power_measurement_environment.md`.
- Every complete experiment is recorded as `xx-exp` in `QUALITY.md`.
- Every next experiment plan is written as `docs/exec-plans/xx-plan.md`.
