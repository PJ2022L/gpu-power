# Next Iteration Plan

本文件是当 E2E 测试集 `MSAE >= 15%` 时必须填写的下一轮计划模板。不允许盲目增加 benchmark；必须先完成 error review。

## Error Review Questions

每轮 review 必须回答：

- 哪个真实算子误差最大？
- 哪个 shape 误差最大？
- 是 average power 错，dynamic power 错，还是 energy 错？
- static + const baseline 是否错误？
- kernel duration 是否太短？
- power trace 和 kernel window 是否错位？
- H800 clock / temperature 是否漂移？
- 哪些 SASS category 残差最大？
- 是否缺少某类 benchmark？
- 是否 memory behavior 没有被正确表示？
- 是否 Tensor Core activity 没有被正确表示？
- 是否 L2 hit / HBM traffic 没有被正确区分？
- 是否 branch / sparse index / softmax 类行为缺失？
- 是否 SASS 动态计数方式错误？
- 是否存在强共线导致系数不稳定？

## Required Plan Fields

```text
next_iter:
source_e2e_report:
source_fit_report:
worst_operator:
worst_shape:
dominant_error_type:
root_cause_hypothesis:
new_benchmarks:
  - benchmark_name:
    missing_behavior:
    source_sass_category:
    expected_operator_error_reduction:
    required_metrics:
    success_criterion:
modeling_changes:
new_metrics:
human_review_required:
```

## Decision Rules

| Observation | Plan direction |
| --- | --- |
| static/dynamic both biased | Revisit `.agents/knowledge/STATIC_POWER_MODEL.md` and baseline data |
| dynamic error high, static ok | Add/extend SASS category microbenchmarks |
| tensor-heavy shapes fail | Add WGMMA/HGMMA/LDSM/TMA/tensor-memory mix benchmarks |
| sparse FlashMLA fails | Add sparse index, dequantization, branch/control, DSM/barrier benchmarks |
| memory-bound shapes fail | Add L2/HBM/global load/store/TMA copy benchmarks |
| coefficients unstable | Add orthogonal benchmarks or use ridge/NNLS |
| SASS counts inconsistent | Fix SASS dynamic count extraction before new power runs |

## Current Placeholder

No H800 E2E evaluation has been recorded yet.
