# E2E Evaluation Report

本文件是 E2E 测试集报告模板。真实结果只能由 H800 agent 基于 `experiments/e2e_testset/` raw/processed 数据填写。

## Testset Boundary

真实算子测试集只作为测试集，原则上只测一次或少量重复，不参与模型拟合。

测试集包括：

- FlashMLA Dense Decoding
- FlashMLA Sparse Decoding
- FlashMLA Sparse Prefill
- GEMM
- FlashAttention v3

每个算子需要覆盖多个 shape，shape 数量可以逐步增加。

## Required Output

```text
experiments/e2e_testset/raw/
experiments/e2e_testset/processed/
experiments/e2e_testset/pred_vs_measured.csv
.agents/knowledge/E2E_EVALUATION_REPORT.md
```

## Required Columns

每个测试样本必须记录：

- operator name
- kernel name
- input shape
- dtype
- batch size
- sequence length
- head num
- kv head num
- head dim
- block size
- sparse ratio / top-k blocks
- GEMM M/N/K
- runtime
- measured average power
- measured dynamic power
- measured energy
- predicted average power
- predicted dynamic power
- predicted energy
- MSAE sample contribution
- Nsight Compute counters
- SASS instruction summary

## Metrics

Use `.agents/knowledge/METRICS.md` definitions:

```text
MSAE = mean(|P_pred - P_meas| / P_meas) * 100%
dynamic_power_error = |P_dynamic_pred - P_dynamic_meas| / P_dynamic_meas
energy_error = |E_pred - E_meas| / E_meas
latency_error = |T_pred - T_meas| / T_meas
```

## Report Template

```text
model_id:
static_model_id:
dynamic_iter:
testset_version:
date:
gpu_uuid:
environment_artifact:
overall_msae:
overall_dynamic_power_error:
overall_energy_error:
overall_latency_error:
worst_operator:
worst_shape:
decision: pass | iterate | human_review
```

If `MSAE >= 15%`, complete `.agents/knowledge/NEXT_ITERATION_PLAN.md` before starting another benchmark round.
