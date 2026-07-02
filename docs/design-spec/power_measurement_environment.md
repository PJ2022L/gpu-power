# Power Measurement Environment

## Purpose

GPU power measurements are sensitive to frequency, voltage, temperature, other GPU processes, clock throttling, and profiler overhead. This document defines the environment required before trusting H800 power data.

## Required Environment

Run valid experiments only when:

- the target machine is an H800 server,
- the experiment runs inside `operatorsforge:h800-v1.0` / `l2_mla_study`,
- exactly one target GPU is selected for the experiment,
- no unrelated process is running on the target GPU,
- persistence mode is enabled if permitted,
- SM clock is locked or continuously recorded,
- memory clock is locked or continuously recorded,
- power limit is fixed or recorded,
- temperature is recorded before, during, and after measurement,
- thermal throttling and power throttling are absent or explicitly recorded,
- energy/power runs are separate from NCU profiler runs.

## Sources Of Measurement Drift

| Factor | Why it matters | Required action |
| --- | --- | --- |
| SM frequency | Dynamic power and runtime change with clock. | Lock with `nvidia-smi -lgc` if possible; otherwise record continuously. |
| Memory frequency | Memory instruction energy/runtime depends on HBM clock. | Lock with `nvidia-smi -lmc` if possible; otherwise record continuously. |
| Voltage | Voltage follows clock and power policy; it changes dynamic power. | Record clock and power-limit state; note that direct voltage may not be exposed. |
| Other GPU processes | They contaminate power traces and cache behavior. | Reject run unless target GPU is exclusive. |
| Temperature | Leakage/static power changes with temperature. | Warm up consistently and record temperature trace. |
| Power cap throttling | Runtime and power plateau become policy-limited. | Reject or mark invalid unless intentionally studying capped behavior. |
| Thermal throttling | Changes clocks and power behavior. | Reject or mark invalid. |
| Profiler overhead | NCU changes runtime and execution behavior. | Never use profiled runtime for energy measurement. |

## Pre-Run Checks

Run before every experiment:

```bash
nvidia-smi -L
nvidia-smi -i <GPU_ID>
nvidia-smi pmon -i <GPU_ID>
nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
nvidia-smi --query-gpu=index,uuid,name,power.limit,power.draw,clocks.sm,clocks.mem,temperature.gpu,utilization.gpu --format=csv
```

Log all outputs under `experiments/logs/`.

## Recommended Control Policy

If permissions allow:

```bash
nvidia-smi -i <GPU_ID> -pm 1
nvidia-smi -i <GPU_ID> -pl <POWER_LIMIT_W>
nvidia-smi -i <GPU_ID> -lgc <SM_CLOCK_MHZ>,<SM_CLOCK_MHZ>
nvidia-smi -i <GPU_ID> -lmc <MEM_CLOCK_MHZ>,<MEM_CLOCK_MHZ>
```

If any command fails, record the failure and mark the run as less controlled.

## Valid Run Criteria

A run is valid only if:

- target GPU is isolated,
- command and hyperparameters are logged,
- clock/power/temperature metadata exist,
- power trace reaches a steady plateau,
- no unplanned throttling occurs,
- energy run is not an NCU run,
- repeated runs are within expected variance.

## Invalid Run Criteria

Reject or quarantine a run if:

- another user process is present on the GPU,
- clocks drift without being recorded,
- power limit changes mid-run,
- thermal or power throttling occurs,
- NCU instrumentation was used for the power run,
- logs do not include command, hyperparameters, and GPU metadata.
