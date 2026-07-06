# Dynamic Power Model

本文件定义 H800 Wattchmen-style SASS 指令级动态功耗模型。实验迭代报告写入 `.agents/knowledge/DYNAMIC_POWER_ITER_<N>_REPORT.md`。

## Source

- Wattchmen paper: `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`
- AccelWattch ubench reference: `.agents/library/benchmarks/accelwattch-ubench/`
- Microbenchmark catalog: `.agents/knowledge/MICROBENCHMARK_CATALOG.md`
- Metrics: `.agents/knowledge/METRICS.md`

## Iteration Loop

默认：

```text
max_iter = 10
target_msae = 15%
```

Loop:

```python
for iter in range(max_iter):
    build_or_extend_microbenchmarks()
    extract_sass_and_dynamic_instruction_counts()
    measure_power_and_runtime()
    fit_or_correct_linear_model()
    evaluate_on_e2e_testset()
    if MSAE < 15:
        break
    else:
        review_error_and_generate_next_benchmarks()
```

每轮输出：

```text
experiments/dynamic_power/iter_<N>/
```

## Model Form

基本形式：

```text
P_dynamic_pred = sum_i count_i * coeff_i + residual
```

或使用 normalized activity：

```text
P_dynamic_pred = sum_i activity_i * coeff_i + residual
```

`i` 是 SASS instruction category 或 hardware behavior category。

必须考虑的类别：

- FP32
- FP16/BF16
- INT
- Tensor Core
- global load
- global store
- shared memory
- L2 hit
- HBM access
- branch/control
- shuffle
- atomic
- conversion
- synchronization
- residual/misc

## Fitting Requirements

拟合时必须：

- 检查矩阵 condition number。
- 检查 benchmark coverage。
- 检查 instruction categories 是否强共线。
- 默认使用 non-negative least squares 或等价约束优化。
- 负动态 RHS 行不能进入 accepted fit；必须 quarantine 并解释。
- 负 SASS 系数不能进入 accepted energy table。
- 负预测功耗不能进入 accepted validation。
- 普通 least squares / ridge regression 只能作为诊断 baseline，不能作为最终 accepted 模型，除非它们也满足全部非负约束。
- 保留 train / validation split。
- 不允许把最终测试集 FlashMLA / GEMM / FlashAttention v3 用作训练集。

## Iteration Output Schema

```text
experiments/dynamic_power/iter_<N>/
  raw/
    microbench_power/
    sass/
    ncu/
  processed/
  sass_counts.csv
  ncu_metrics.csv
  model_coefficients.csv
  fit_report.md
  pred_vs_measured.csv
```

## Required Reports

`fit_report.md` 必须包含：

- training benchmark list
- validation benchmark list
- static model version
- feature/category list
- condition number
- rank diagnostics
- coefficient table summary
- negative coefficient count before constraints
- residual distribution
- coverage report
- missing categories
- decision: accept / extend benchmark / modeling review

`.agents/knowledge/DYNAMIC_POWER_ITER_<N>_REPORT.md` 必须链接本轮 raw/processed/report artifacts，并说明下一轮计划是否更新。
