# Static And Constant Power Model

本文件定义 H800 static + constant active power baseline 的建模计划和产物格式。本文件不是实验结果；H800 agent 完成实验后在此追加模型版本、参数和误差。

## Source

- AccelWattch paper: `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`
- AccelWattch ubench: `.agents/library/benchmarks/accelwattch-ubench/`
- Wattchmen paper: `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`
- Measurement protocol: `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`

如果 `.agents/library/benchmarks/accelwattch-ubench/` 不存在，先查 `.agents/knowledge/ROUTE_MAP.md`，不要假设旧路径。

## Goal

在 H800 上建立 `static + constant active power baseline`，供 dynamic SASS model 扣除 baseline：

```text
P_dynamic = P_meas - P_static_const
E_dynamic = P_dynamic * runtime
```

## Required Baseline States

必须逐步测量：

- idle power
- persistence mode idle power
- locked clock idle power
- empty kernel active power
- low activity kernel power
- temperature stabilized power
- 不同 SM clock 下的 baseline power
- 不同 memory clock 下的 baseline power
- 不同 power limit 下的 baseline power

## Model Form

目标模型：

```text
P_static_const = f(clock_sm, clock_mem, temperature, power_limit, active_state)
```

MVP 允许先使用：

```text
P_static_const = mean(empty_kernel_loop_power)
```

但必须记录局限性：

- 不区分 idle constant 与 active static。
- 不建模 temperature/clock/power_limit。
- 对低 occupancy 或短 kernel 可能偏差大。
- 不能解释不同 active_state 的 baseline 差异。

非负约束：

- `P_idle >= 0`
- `P_active_state >= 0`
- `P_static = P_active_state - P_idle >= 0`

如果 `P_static < 0`，该 baseline 版本无效。不要通过静默 clamp 让它进入 dynamic model；先检查 GPU isolation、active-no-op 饱和度、采样窗口、温度/clock drift 和 trace 对齐。

## Output Layout

```text
experiments/static_power/
  raw/
    <baseline_id>/
      nvidia_smi_trace.*
      nvml_trace.*
      dcgm_trace.*              # if available
      command.log
      metadata.yaml
      power_trace.csv
      summary.yaml
  processed/
    static_power_samples.csv
    static_model_parameters.json
    static_model_error.csv
  plots/
    plot_static_power.py
    static_power_vs_clock.png
```

Recommended collection entrypoint:

```bash
GPU_ID=0 scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml idle
GPU_ID=0 scripts/collect_static_power_baselines.sh configs/power/nvml_policy.yaml empty_kernel_active -- <empty-kernel-loop-command>
```

必须保存：

- raw nvidia-smi / NVML / DCGM trace
- benchmark command
- benchmark runtime
- clock / temperature / power limit
- processed csv
- fitting script
- static model parameters
- model error

## Recommended Experiment Matrix

| State | Description | Required metadata |
| --- | --- | --- |
| `idle` | no kernel, no unrelated process | persistence, clocks, temperature |
| `idle_pm_on` | persistence mode enabled idle | command status for `nvidia-smi -pm 1` |
| `idle_locked_clock` | idle with locked SM/mem clock if permitted | lock command and failure reason |
| `empty_kernel_loop` | repeated empty kernel to create active window | loop count, runtime, active window |
| `low_activity_kernel` | nanosleep or low-switching full-SM kernel | CTA count, warp count, loop count |
| `temp_stabilized` | baseline after warmup | start/end temp, drift |
| `sm_clock_sweep` | multiple SM clocks | supported clocks, actual clocks |
| `mem_clock_sweep` | multiple memory clocks | supported clocks, actual clocks |
| `power_limit_sweep` | multiple power limits | actual power cap and throttling |

## Acceptance Criteria

- 每个 baseline state 至少 5 repeats，除非明确标为 bring-up。
- median power CV、runtime CV、temperature drift 满足 `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md` 阈值。
- 所有失败命令写入 log。
- baseline 版本号被 dynamic model 引用。

## Initial Model Record

实验完成后追加：

```text
model_id:
date:
gpu_uuid:
clock_policy:
power_limit:
baseline_states_used:
P_idle:
P_static_const:
fit_formula:
model_error:
limitations:
```
