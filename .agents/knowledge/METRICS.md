# Metrics

本文件定义 H800 Wattchmen-style 功耗模型的默认评价指标。任何实验如果使用不同定义，必须在本文件追加一节说明原因、适用范围和影响。

## Primary Metric

项目主目标：

```text
MSAE < 15%
```

默认定义：

```text
MSAE = mean(|P_pred - P_meas| / P_meas) * 100%
```

其中：

- `P_pred`: 模型预测的算子 active window 平均功耗。
- `P_meas`: H800 上非 profiler 运行测得的算子 active window 平均功耗。
- testset: FlashMLA、GEMM、FlashAttention v3。FlashMLA 至少区分 Dense Decoding、Sparse Decoding、Sparse Prefill。

## Required Secondary Metrics

每个 E2E 测试样本必须同时记录：

```text
dynamic_power_error = |P_dynamic_pred - P_dynamic_meas| / P_dynamic_meas
energy_error        = |E_pred - E_meas| / E_meas
latency_error       = |T_pred - T_meas| / T_meas
```

报告时同时给出单样本值和 across-testset mean/median/max。

## Power And Energy Definitions

```text
P_meas = benchmark active window 内的平均功耗
P_static_const = idle/static/constant active baseline
P_dynamic = P_meas - P_static_const
E = P_meas * runtime
E_dynamic = P_dynamic * runtime
```

`P_static_const` 必须引用 `.agents/knowledge/STATIC_POWER_MODEL.md` 中的 static/const baseline 版本。不能把 profiler runtime 或 exploratory power 当作 `P_meas`。

非负约束：

- `P_meas >= 0`
- `P_static_const >= 0`
- `P_dynamic >= 0`
- `E >= 0`
- `E_dynamic >= 0`
- `P_pred >= 0`
- `P_dynamic_pred >= 0`

如果 baseline subtraction 得到负动态功耗，该样本不能进入 accepted fit 或 accepted validation。必须先标记为 invalid/quarantined，并检查 baseline、active window、clock/temperature drift 和采样对齐。

## Active Window Rule

`P_meas` 必须来自 benchmark active window：

- 不包含 launch 前 idle prefix。
- 不包含 kernel 完成后的 cooldown。
- 对短 kernel 必须用 loop 放大 active window。
- 多 kernel operator 使用 operator call active window；kernel-level attribution 可用于解释，但 average power ground truth 以 operator window 为准。

## Test/Train Boundary

真实算子测试集原则上只用于 E2E validation，不进入 microbenchmark model fitting。不得用 FlashMLA/GEMM/FlashAttention v3 的最终测试样本拟合 SASS 系数。

## Source

- Wattchmen 方法来源：`.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`
- 当前模型计划：`.agents/knowledge/POWER_MODEL_PLAN.md`
- H800 测量协议：`.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`
