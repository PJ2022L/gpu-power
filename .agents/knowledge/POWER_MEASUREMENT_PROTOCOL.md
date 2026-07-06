# H800 Power Measurement Protocol

本文件是 H800 Docker agent 后续直接执行实验时的测功规范。当前仓库不运行 GPU benchmark，本文件只定义流程、日志和验收标准。

## 来源

- `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`
- `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`
- `.agents/library/docs/nsight-compute.pdf`
- `.agents/library/docs/nsight-systems.pdf`
- `.agents/library/docs/CUDA_Binary_Utilities.pdf`
- `.agents/library/papers/wattchmen/04-measurement-protocol.md`

## 测量目标

| 指标 | 定义 | 用途 |
| --- | --- | --- |
| idle power | 没有目标 GPU kernel 时的 baseline power | 估计 `P_const` |
| static power | active-no-op power 与 idle power 的差 | 初始估计 `P_static` |
| dynamic power | active power 扣除 idle/static 后的部分 | SASS dynamic energy table |
| average power | 稳态窗口平均或中位功耗 | operator/microbenchmark 对比 |
| peak power | 稳态或全窗口峰值 | 检测 power cap 和异常 |
| energy per kernel | power 积分或 energy counter 差值 | 训练/验证目标 |
| energy per token | operator energy / token count | FlashMLA 推理评估 |
| energy per FLOP | dynamic energy / FLOPs | GEMM/FlashMLA compute path |
| energy per byte | dynamic energy / bytes | HBM/L2/cache path |
| energy-delay product | energy * runtime | 性能功耗联合指标 |

## 工具比较

| 工具 | 采样粒度 | 单 kernel 能力 | 时间序列 | 自动化 | 局限性 | 项目用途 |
| --- | --- | --- | --- | --- | --- | --- |
| `nvidia-smi` | 粗，依赖驱动 | 不适合短 kernel | 可循环 query | 高 | shell 开销、采样慢 | 环境检查、clock/power/进程记录 |
| `nvidia-smi dmon` | 粗到中等 | 不适合短 kernel | 是 | 中 | 字段有限 | 备份 power/util log |
| NVML | 驱动支持的 power/energy API | 需长窗口或 loop 放大 | 是 | 高 | 采样粒度有限，energy counter 可能不可用 | energy mode 主工具 |
| DCGM | 数据中心监控 | 不适合微秒 kernel | 是 | 高 | 当前 library 未收录手册，需部署支持 | 可作为独立对照 |
| Nsight Systems | timeline 级 | 能定位 kernel launch | 是 | 中 | power 不是主目标；trace overhead | operator kernel list、NVTX、multi-kernel 聚合 |
| Nsight Compute | kernel profiler | 强 | report/export | 中 | replay/profiler overhead，不能测 ground truth power | SASS counts、cache/tensor metrics |
| CUPTI | 低层 API | 可细粒度 | 是 | 低到中 | 实现复杂，权限/版本敏感 | 后续可选 |
| 外接功率计 | 取决于设备 | 通常板级/节点级 | 是 | 低 | 难分单 GPU/单 kernel | 若可用，用于校验 NVML |

## 标准流程

### 1. 环境确认

```bash
nvidia-smi -i <GPU_ID>
nvidia-smi pmon -i <GPU_ID>
nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
```

要求：

- 目标 GPU 独占，无其他用户进程。
- 记录 Docker image/container、hostname、GPU UUID。
- 记录 driver、CUDA runtime/toolkit、NCU/Nsys、nvcc、git commit。
- 记录 MIG/MPS 状态。

### 2. Clock / power policy

优先锁定或记录：

```bash
nvidia-smi -i <GPU_ID> -pm 1
nvidia-smi -i <GPU_ID> -pl <POWER_LIMIT_W>
nvidia-smi -i <GPU_ID> -lgc <SM_CLOCK_MHZ>,<SM_CLOCK_MHZ>
nvidia-smi -i <GPU_ID> -lmc <MEM_CLOCK_MHZ>,<MEM_CLOCK_MHZ>
```

如果权限不足或 H800 系统不支持：

- 记录失败原因；
- 采样中持续记录 actual SM/memory clocks；
- 标记该 run 为 `clock_control=record_only`。

### 3. Baseline

每个 session 至少采：

1. idle baseline: 无 kernel，固定窗口。
2. active-no-op baseline: low-switching kernel，尽量 all-SM active。
3. NOP loop 或 minimal instruction loop: 用于 loop/control overhead 约束。

baseline 必须保存 raw trace 和 summary，后续 microbenchmark/model fitting 引用 baseline id。

### 4. Warmup / cooldown

- 正式测量前 warmup 到温度稳定区间。
- 每次 energy run 后 cooldown，Wattchmen baseline 为约 60 秒。
- 如果不 cooldown，需要记录并证明 repeated-run variance 合格。

### 5. Energy mode

- 不挂 Nsight Compute。
- kernel loop 放大到长稳态窗口。
- Wattchmen baseline：每个 microbenchmark 5 次重复，每次约 180 秒。
- 采样开始早于 kernel launch，结束晚于 kernel completion。
- 从 trace 中选择 steady-state plateau 做积分和 power median。

### 6. Profiler mode

- 用较短 iterations 收 NCU metrics。
- metric counts 必须验证随 iterations 线性后才能 scale 到 energy mode。
- 不使用 profiler runtime 作为 energy runtime。

### 7. Operator power ground truth

- Phase 1 只做 NCU/Nsys profiling，不采 validation power ground truth。
- Phase 4 单独做 operator power ground truth：不挂 NCU，使用 NVML，运行完整 operator call path。
- 如果 operator launch 多个 kernels，ground truth 是 operator-level 聚合，不是单 kernel 峰值。

## NVML 采样字段

每条 sample 推荐：

```text
timestamp_ns,gpu_id,gpu_uuid,power_mw,total_energy_mj,temperature_c,sm_clock_mhz,mem_clock_mhz,gpu_util_pct,mem_util_pct
```

如果 `total_energy_mj` 不可用，用 power 积分：

```text
energy_j = sum(power_w[i] * delta_t_s[i])
```

同时记录 energy counter 是否可用、是否 wrap、积分方式。

## Steady-state 窗口选择

窗口必须满足：

- startup/shutdown transient 被排除；
- GPU utilization 达到设计目标；
- SM/memory clock 稳定；
- power 没有明显斜坡；
- temperature drift 在阈值内；
- 无 power cap/thermal throttling；
- benchmark 输出 checksum/sink 有效。

建议保存：

- `window_start_ns`;
- `window_end_ns`;
- `selection_reason`;
- `excluded_prefix_sec`;
- `excluded_suffix_sec`。

## 重复性阈值

Main Agent 用以下阈值判断一次 microbenchmark 或 operator power run 是否 valid。首轮阈值偏保守，后续可按 H800 实测经验调整。

| 指标 | 计算范围 | Pass 阈值 | Warn 阈值 | Fail 阈值 |
| --- | --- | --- | --- | --- |
| steady-state median power CV | 同一 benchmark 的正式 repeats | `<= 1.5%` | `1.5% - 3%` | `> 3%` |
| integrated energy CV | 同一 benchmark repeats | `<= 2%` | `2% - 4%` | `> 4%` |
| runtime CV | 同一 benchmark repeats | `<= 1%` | `1% - 2%` | `> 2%` |
| steady-state temperature drift | 单次 run 窗口内 max-min | `<= 3 C` | `3 - 5 C` | `> 5 C` |
| start temperature spread | repeats 起始温度 max-min | `<= 5 C` | `5 - 8 C` | `> 8 C` |
| SM clock drift | steady-state 窗口内 max-min | `<= 15 MHz` 或 locked exact | `15 - 60 MHz` | `> 60 MHz` |
| memory clock drift | steady-state 窗口内 max-min | `<= 15 MHz` 或 locked exact | `15 - 60 MHz` | `> 60 MHz` |
| power plateau MAD/median | 单次 steady-state samples | `<= 2%` | `2% - 4%` | `> 4%` |
| target opcode count CV | profiler repeats | `<= 0.5%` | `0.5% - 1%` | `> 1%` |
| intended cache hit-rate deviation | 设计目标 vs measured | `<= 5 pp` | `5 - 10 pp` | `> 10 pp` |

处理规则：

- `Pass`: 可进入 fitting。
- `Warn`: 可暂存，但 fitting 时降权或标记；需要 Main Agent 说明原因。
- `Fail`: 不进入正式 fitting；先重跑或修正环境/benchmark。

特殊情况：

- 对极短 operator 不直接测单次 kernel power；必须 loop 放大或使用 operator-level repeated loop。
- 对 memory-bound benchmark，如果 power CV 合格但 cache hit-rate fail，不能进入对应 hierarchy 训练集。
- 对不能锁频的 H800 系统，clock drift 阈值仍用于判定 run 是否可用。

## 日志字段

每次实验 shell 脚本必须在 log 开头写入：

```text
date_time_iso=
hostname=
docker_image=operatorsforge:h800-v1.0
container_name=l2_mla_study
git_commit=
command=
args=
gpu_id=
gpu_uuid=
gpu_name=
driver_version=
cuda_version=
nvcc_version=
ncu_version=
nsys_version=
power_limit_w=
locked_sm_clock_mhz=
locked_mem_clock_mhz=
actual_sm_clock_mhz_before=
actual_mem_clock_mhz_before=
temperature_c_before=
persistence_mode=
mig_mode=
mps_state=
benchmark_name=
operator_name=
kernel_filter=
shape_json=
iterations=
unroll_factor=
grid_dim=
block_dim=
data_size_bytes=
warmup_seconds=
measurement_seconds=
cooldown_seconds=
repeat_index=
baseline_id=
notes=
```

项目规则：脚本运行 Python 或 C++ 程序时，要把运行命令和超参数打印到 log 文件，以便复现。

## Nsight Compute 指标

优先收：

- `sass__inst_executed_per_opcode_with_modifier_all`；
- 若不可用，降级到 `sass__inst_executed_per_opcode_with_modifier_selective`、`sass__inst_executed_per_opcode`、`sass__inst_executed_per_opcode_category`；
- global/shared/local load-store counts；
- L1/L2/DRAM sector/byte metrics；
- tensor pipe / WGMMA/HGMMA 相关 metrics；
- occupancy/register/shared memory；
- branch/predicate/divergence metrics。

NCU metric names 必须从 H800 机器上 `ncu --query-metrics` 确认，不在知识库中硬编码为最终值。

## Nsight Systems 使用

用于：

- operator launch timeline；
- FlashMLA splitkv/combine 多 kernel 聚合；
- NVTX range 与 kernel 对齐；
- Python/CUDA API overhead 判断；
- 导出 SQLite/CSV 做 kernel list。

不用于：

- 替代 NVML energy ground truth；
- 替代 NCU SASS opcode counts。

## 干扰控制

必须检查并记录：

- 其他 GPU 进程；
- CPU I/O 和 log 写入是否在测量窗口中；
- GPU temperature；
- power limit 和 throttling；
- clock drift；
- ECC/MIG/MPS；
- persistence mode；
- display/graphics process；
- 容器中是否有后台 worker；
- network/NVLink traffic 是否影响目标 GPU；
- benchmark 是否包含 host synchronization 或 data copy。

## 异常值处理

- 保留所有 raw trace，不删除。
- summary 中标注 included/excluded repeats。
- 先按明确规则排除 fail run，再计算 median/mean。
- 至少报告 median、mean、std、CV、MAD、min、max。
- 若 repeats 少于 5，只能作为 bring-up 数据，不作为正式 fitting 数据。

## 输出文件建议

```text
experiments/<exp_id>/
  raw/power/<bench_or_operator>/<repeat>/
  raw/ncu/<bench_or_operator>/
  raw/nsys/<operator>/
  processed/steady_state_windows/
  processed/matrix_inputs/
  reports/repeatability/
  logs/
```

## 禁止事项

- 不在 profiler mode 下采 ground-truth power。
- 不把 H100/B200 规格写成 H800 实测规格。
- 不在目标 GPU 有其他进程时运行正式测量。
- 不把短 kernel 单次 power sample 当作 kernel energy。
- 不丢弃 raw logs。
