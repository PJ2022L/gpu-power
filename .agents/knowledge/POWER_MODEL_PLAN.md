# H800 Power Model Plan

本文件给出从 microbenchmark 到 GEMM/FlashMLA/FlashAttention v3 operator power prediction 的建模路线。目标是复现 Wattchmen 方法论，而不是先做黑盒拟合。

## 来源

- `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`
- `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`
- `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md`
- `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md`
- `.agents/library/benchmarks/gpuwattch-ubench/`
- `.agents/library/benchmarks/accelwattch-ubench/`
- `.agents/library/docs/nsight-compute.pdf`

## 基础公式

```text
total_energy = average_power * runtime
E_total = E_const + E_static + E_dynamic
E_const = P_idle * T
E_static = P_active_static * T
E_dynamic = E_active_measured - E_const - E_static
```

H800 V1:

```text
P_idle = median_power(idle_baseline_steady_state)
P_active_static = median_power(active_noop_steady_state) - P_idle
```

动态模型：

```text
E_dynamic = sum_i count_i * e_i
A x = b
x >= 0
```

memory hierarchy split:

```text
E_mem = count_l1 * e_l1 + count_l2 * e_l2 + count_hbm * e_hbm
```

其中 `count_l1/count_l2/count_hbm` 由 NCU hit-rate/sector metrics 估算，不只看 SASS opcode。

## 原子操作分解

| Component | 代表行为 | 初始建模 |
| --- | --- | --- |
| compute component | INT/FP/SFU/dequantization | SASS opcode energy |
| tensor component | WGMMA/HGMMA/MMA/LDSM | tensor opcode + operand movement |
| memory component | LDG/STG/LDGSTS/TMA/HBM | opcode count + hierarchy split |
| cache component | L1/L2 hit/miss | hit-rate weighted energy |
| shared component | LDS/STS/LDSM/bank conflict | opcode + conflict category |
| control component | ISETP/BRA/PLOP3/SEL/SHFL | opcode energy |
| synchronization component | BAR/BSYNC/mbarrier/cluster barrier | opcode or microbenchmark bucket |
| launch/overhead component | short kernel launch, splitkv/combine overhead | separate baseline/correction if needed |

## 训练数据结构

每个 microbenchmark 训练样本：

```yaml
bench_id:
target_family:
target_opcode:
shape:
energy_mode:
  runtime_s:
  steady_state_power_w_median:
  integrated_energy_j:
  baseline_id:
  repeatability:
profiler_mode:
  sass_counts:
  cache_metrics:
  tensor_metrics:
  occupancy:
sass_dump:
  path:
quality:
  valid: true/false
```

构建：

- `A`: microbenchmarks x opcode/hierarchy features；
- `b`: dynamic energy；
- `x`: non-negative energy per feature；
- `weights`: repeated-run uncertainty 的倒数，可选。

## Fitting 流程

1. 读取 valid microbenchmark summaries。
2. 对每个 run 扣除 `P_idle` 和 `P_active_static`。
3. 聚合同一 benchmark repeats，优先用 median dynamic energy。
4. 构建 raw opcode feature matrix。
5. 对 memory instructions 按 L1/L2/HBM 拆分。
6. 对 unsupported modifier 保留 raw column，同时创建 grouped/bucketed column。
7. 求 NNLS / constrained least squares。
8. 输出 energy table、residual report、rank/conditioning、poorly constrained opcode list。
9. 用 holdout microbenchmark 或 mix benchmark 做 sanity check。

## 重建 Operator 功耗

对一个 operator instance：

```text
E_pred_operator =
  sum_kernels [
    (P_idle + P_active_static_adjusted) * T_kernel
    + sum_direct count_i * e_i
    + sum_grouped count_j * e_group_j
    + sum_scaled count_k * e_scaled_k
    + sum_bucketed count_l * e_bucket_l
  ]
```

operator average power:

```text
P_pred_operator = E_pred_operator / T_operator_wall
```

FlashMLA 多 kernel 情况：

- `splitkv_mla` 和 `combine` 必须都进入 operator aggregation。
- 若 programmatic dependent launch 导致 overlap，`T_operator_wall` 用 Nsys/NVML 对齐的 operator wall window；各 kernel energy attribution 只用于解释，不直接把 overlapped wall time重复加 static。

## FlashMLA 重建策略

### Dense Decoding

预测项：

- Q/KV global or TMA load energy；
- WGMMA/HGMMA QK；
- softmax CUDA core/SFU/reduction；
- WGMMA/HGMMA PV；
- output/global store；
- splitkv/combine；
- static/idle baseline。

优先对比：

- memory-bound dense shape；
- compute-bound dense shape。

如果 memory-bound error 高：扩展 HBM/L2/TMA microbenchmark。

如果 compute-bound error 高：扩展 WGMMA/HGMMA/LDSM/softmax benchmark。

### Sparse Decoding

预测项：

- sparse index load/address calc；
- FP8 KV load；
- FP8 dequantization/conversion/scale multiply；
- DSM/st.async/cluster barrier；
- QK/PV tensor；
- softmax/reduction；
- output write。

如果 error 随 `topk` 增大下降，说明 fixed overhead/prologue/epilogue 或 launch/static 建模不足。

如果 error 随 irregularity 增大，说明 sparse index/cache locality 模型不足。

### Sparse Prefill

预测项：

- large `s_q` Q load；
- sparse gather；
- QK/PV tensor；
- softmax/reduction；
- output/max_logits/lse write。

必须把 decoding 和 prefill 分开验证，因为 `s_q` 和 grid/occupancy 完全不同。

## 流水线重叠处理

不能简单把所有阶段按时间串行相加。H800 V1 先采用 energy attribution 的线性动态能量模型，因为 Wattchmen 的训练目标是总 dynamic energy，而不是阶段 wall-time。

需要处理 overlap 的地方：

- TMA copy 与 WGMMA；
- CUDA core softmax 与 Tensor Core；
- splitkv 和 combine 的 dependent launch overlap；
- sparse dequantization 与 tensor compute；
- DSM exchange 与 MMA。

V1 处理：

- dynamic energy 仍按 opcode counts 相加；
- static energy 按 operator wall time 加一次；
- 多 kernel 的 static 不按 kernel runtime 重复叠加到超过 operator wall window。

V2 可选 correction：

```text
E_dynamic_corrected =
  E_opcode
  + alpha_tensor_overlap * overlap_indicator_tensor_softmax
  + alpha_mem_overlap * overlap_indicator_tma_wgmma
  + alpha_occupancy * occupancy_gap
```

只有在 microbenchmark residual 低、operator error 仍高时才引入 correction。

## 模型验证

每个 validation report 至少输出：

| 指标 | 公式 |
| --- | --- |
| power error % | `abs(P_pred - P_measured) / P_measured * 100` |
| energy error % | `abs(E_pred - E_measured) / E_measured * 100` |
| latency error % | 如果预测 latency，使用同样 MAPE |
| dynamic energy error % | 扣 baseline 后比较 |
| coverage % | directly/grouped/scaled/bucketed attributed instruction fraction |
| unknown opcode top-k | 未覆盖或 bucketed 贡献最高的 opcode |
| residual summary | microbenchmark fitting residual |

通过标准：

- 首轮目标：operator average power/energy error <= 15%。
- 单一 shape 可以 warn，但 across shapes MAPE 必须报告。
- 若 power error <=15% 但 energy error >15%，检查 runtime/window 对齐。
- 若 energy error <=15% 但 attribution 明显错误，仍需扩展 microbenchmark。

## MVP 路线

### Step 0: H800 platform confirmation

- 确认 GPU name/UUID/SM count/HBM/L2/clocks/power limit。
- 确认 NVML energy counter。
- 确认 NCU opcode metrics。

### Step 1: Idle baseline

- idle power；
- active-no-op；
- NOP loop。

输出 `P_idle`, initial `P_static`, repeatability report。

### Step 2: HBM bandwidth benchmark

- global load/store；
- L1/L2/HBM hit/miss；
- 32/64/128-bit width。

输出 memory hierarchy energy 初表。

### Step 3: Tensor Core benchmark

- one BF16/FP16 WGMMA/HGMMA shape；
- LDSM；
- shared staging；
- mbarrier if present。

输出 tensor energy 初表。

### Step 4: L2-sensitive benchmark

- working set around H800 L2；
- pointer chasing / streaming variants；
- cache metrics 验收。

输出 cache split 校准。

### Step 5: GEMM validation

- 先选稳定 cuBLAS/CUTLASS GEMM；
- NCU top-k SASS；
- Phase 4 单独采 power；
- 比较预测。

### Step 6: FlashMLA dense decoding

- memory-bound 和 compute-bound shapes；
- splitkv/combine 聚合；
- error root cause。

### Step 7: Sparse decoding / sparse prefill

- FP8 sparse decoding；
- sparse index/dequant/DSM；
- sparse prefill large `s_q`。

## Phase 5 回退规则

当 error >15%：

| 观察 | 结论 | 下一步 |
| --- | --- | --- |
| unknown/bucketed opcode 贡献高 | microbenchmark coverage 不足 | 增加 direct benchmark |
| memory-bound shapes error 高 | memory hierarchy split 不足 | 增加 L2/HBM/TMA benchmark |
| compute-bound shapes error 高 | tensor/softmax table 不足 | 增加 WGMMA/LDSM/SFU/reduction benchmark |
| residual 高 | 训练数据或测量问题 | 修 power protocol、重跑 |
| residual 低但所有 operators 偏移 | const/static baseline 错 | 重测 baseline 或引入 occupancy static |
| only sparse error 高 | sparse index/dequant/DSM 未建模 | 增加 sparse-specific benchmark |
| error 与 occupancy 强相关 | static active-SM 假设不足 | 做 active SM sweep，人工评审 |

## 产物版本化

每次完整实验定义为：

```text
micro-benchmark -> fitting/correction -> operator test
```

编号关系：

```text
01-plan.md -> 01-exp -> 02-plan.md
```

每次实验完成后更新：

- root `QUALITY.md`；
- `docs/exec-plans/<next>-plan.md`；
- model artifact version；
- microbenchmark coverage report；
- validation error table。
