# Microbenchmark Catalog

本文件记录 `.agents/library/benchmarks` 和 FlashMLA benchmark 中可复用的 microbenchmark 思想。目标不是直接运行旧代码，而是判断哪些代码可以改造成 H800/Hopper/SM90 的 Wattchmen-style power benchmark。

## 来源

- `.agents/library/benchmarks/gpuwattch-ubench/`
- `.agents/library/benchmarks/accelwattch-ubench/`
- `.agents/library/operators/FlashMLA/benchmark/bench_flash_mla.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_dense_decoding.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_decoding.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_prefill.py`
- `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`
- `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`

## Catalog 总表

| 项目路径 | Benchmark 名称/类别 | 测量目标 | 原始指标 | CUDA | NCU | 功耗采集 | H800 改造价值 | 风险 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `.agents/library/benchmarks/gpuwattch-ubench/functional_benchmarks/` | FP/INT/SFU functional | CUDA Core instruction mix | latency/time/power scripts | 是 | 可加 | 旧脚本有 power flow | High | 代码老、PTX/SASS 不稳定、需 CUDA 12 重写 |
| `.agents/library/benchmarks/gpuwattch-ubench/branching_benchmarks/` | active lanes/branching | divergence/control-flow | time/power scripts | 是 | 可加 | 旧脚本有 power flow | Medium | H800 首版先做 uniform branch |
| `.agents/library/benchmarks/gpuwattch-ubench/memories_benchmarks/` | L1/L2/shared/constant/texture | memory hierarchy | time/power scripts | 是 | 可加 | 旧脚本有 power flow | High | cache 行为需 H800 重新验证 |
| `.agents/library/benchmarks/gpuwattch-ubench/dram_benchmarks/` | DRAM read/write | HBM streaming | time/power scripts | 是 | 可加 | 旧脚本有 power flow | High | 需改成 H800 HBM working set |
| `.agents/library/benchmarks/gpuwattch-ubench/active_cores/` | active cores sweep | active SM/static relation | power scripts | 是 | 可加 | 可改 | Medium | 固定 SM 数策略需更新 |
| `.agents/library/benchmarks/accelwattch-ubench/functional_benchmarks/` | FP/INT/DP/SFU/MOV/REG_FILE | instruction power | CUDA event runtime | 是 | 可加 | 需接 NVML | High | 原目标为 component model |
| `.agents/library/benchmarks/accelwattch-ubench/memories_benchmarks/` | L1/L2/DRAM/shared/constant/texture | cache/memory | CUDA event runtime | 是 | 可加 | 需接 NVML | High | Volta-oriented working sets |
| `.agents/library/benchmarks/accelwattch-ubench/static_power_modeling/` | active/static | idle/active static | runtime | 是 | 可加 | 需接 NVML | High | H800 static model 需重定义 |
| `.agents/library/benchmarks/accelwattch-ubench/tensor_benchmarks/TENSOR/` | WMMA tensor | tensor core | runtime | 是 | 可加 | 需接 NVML | High | 需要升级 WGMMA/HGMMA |
| `.agents/library/operators/FlashMLA/benchmark/bench_flash_mla.py` | FlashMLA vs Torch/FlashInfer | operator latency/throughput | Triton benchmark time | 是 | 可加 | 需接 NVML | High | 缺少 power log 和 kernel filtering |
| `.agents/library/operators/FlashMLA/tests/test_flash_mla_dense_decoding.py` | Dense decode tests | correctness/perf shapes | kernel time, FLOPs, BW | 是 | 可加 | 需接 NVML | High | 需加长循环和日志 |
| `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_decoding.py` | Sparse decode tests | FP8 sparse decoding | kernel time, FLOPs, BW | 是 | 可加 | 需接 NVML | High | 需 isolate full operator |
| `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_prefill.py` | Sparse prefill tests | sparse prefill | kernel time, FLOPs, BW | 是 | 可加 | 需接 NVML | High | 长 shape 需内存确认 |

## gpuwattch-ubench 构造方式

`gpuwattch-ubench` 更早，目录按行为拆分：

- `functional_benchmarks`: FP/INT/SFU；
- `branching_benchmarks`: active lanes；
- `memories_benchmarks`: L1/L2/shared/constant/texture；
- `dram_benchmarks`: DRAM read/write；
- `mix_benchmarks`: instruction mix；
- `active_cores`: active core/SM sweep。

典型特点：

- 通过 `replace_iterations.sh` 或源码替换设置 iteration count。
- 使用 `#pragma unroll` 放大目标操作。
- 使用 sink store 防止 dead-code elimination。
- memory benchmark 使用 pointer chasing、working set 和 inline PTX cache modifiers 控制 L1/L2 行为。
- branching benchmark 通过 lane 条件构造不同 active lanes。

H800 复用策略：

- 保留“目录分类”和“长循环放大窗口”的思想。
- 不直接沿用旧 power scripts。
- 对每个 kernel 增加 SASS dump、NCU metrics、NVML energy mode。
- 使用 H800 实测 SM 数、L2 容量、clock/power policy 重设 grid/block/working set。

## accelwattch-ubench 构造方式

`accelwattch-ubench` 更接近现代 CUDA，典型源码如 `.agents/library/benchmarks/accelwattch-ubench/functional_benchmarks/BE_SP_FP_ADD/BE_SP_FP_ADD.cu`：

- 运行时传入 `iterations`。
- 固定 `THREADS_PER_BLOCK=256`, `NUM_OF_BLOCKS=640` 等配置。
- `#pragma unroll 100` 放大目标指令。
- CUDA events 记录 kernel runtime。
- 输出 result 防止优化。

memory 示例 `.agents/library/benchmarks/accelwattch-ubench/memories_benchmarks/BE_L1D_HIT/BE_L1D_HIT.cu`：

- pointer chasing；
- inline PTX `ld.global.ca.u64`；
- `bar.sync`；
- sink write；
- 目标是控制 L1 hit。

tensor 示例 `.agents/library/benchmarks/accelwattch-ubench/tensor_benchmarks/TENSOR/tensorcore.cu`：

- 使用 WMMA fragment；
- 在 loop 中反复 `wmma::mma_sync`；
- 用 CUDA events 测 runtime。

H800 复用策略：

- functional/memory/static/tensor 分类直接复用。
- WMMA tensor benchmark 必须升级到 SM90 WGMMA/HGMMA 或 CUTLASS/CUTE kernel。
- memory benchmark 必须添加 L1/L2/HBM 真实 hit-rate 验收。
- static_power_modeling 中 `LIGHT_SM` 可作为 active-no-op baseline 参考。

## H800 目标 microbenchmark 类别

### Tensor Core Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | WGMMA/HGMMA dynamic energy，LDSM，shared staging，mbarrier。 |
| 参考代码 | `.agents/library/benchmarks/accelwattch-ubench/tensor_benchmarks/TENSOR/tensorcore.cu`，FlashMLA/CUTLASS SM90 kernels。 |
| 改造方式 | 用 SM90 CUTE/CUTLASS 或 inline PTX 诱导稳定 WGMMA/HGMMA；拆分 tensor math、LDSM、barrier、global-to-shared copy。 |
| 记录指标 | SASS opcode counts、tensor utilization、shared load/store、runtime、power trace。 |
| 风险 | tensor math 与 operand movement 难分离；compiler/toolkit 可能改变 SASS。 |

### CUDA Core FP32/INT/DP/SFU Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | `MOV`, `IADD3`, `IMAD`, `LOP3`, `FADD`, `FMUL`, `FFMA`, `DADD`, `DMUL`, `DFMA`, `MUFU`。 |
| 参考代码 | `gpuwattch-ubench/functional_benchmarks/`, `accelwattch-ubench/functional_benchmarks/`。 |
| 改造方式 | runtime iterations、unroll、independent register chains、sink store、SASS verification。 |
| 记录指标 | opcode count linearity、power median、runtime CV、occupancy。 |
| 风险 | compiler fusion、dead-code elimination、dependency chain 变成 latency benchmark。 |

### HBM Bandwidth Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | `LDG/STG` data width 与 HBM dynamic energy。 |
| 参考代码 | `gpuwattch-ubench/dram_benchmarks/`, `accelwattch-ubench/memories_benchmarks/BE_MEM_DRAM_Acss/`。 |
| 改造方式 | 大 working set streaming；coalesced load/store；扫 32/64/128-bit；确保 L2 miss/DRAM hit。 |
| 记录指标 | DRAM bytes/sectors, L2 hit rate, power, bandwidth。 |
| 风险 | cache reuse、power cap、memory clock drift。 |

### L2 Cache Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | L1 miss/L2 hit 和 L2 miss/DRAM 分离。 |
| 参考代码 | `accelwattch-ubench/memories_benchmarks/BE_L2D_HIT/`, `l2r*/l2w*`。 |
| 改造方式 | working set 大于 L1 小于 H800 L2；stride/pointer chasing；NCU hit-rate 验证。 |
| 记录指标 | `lts__*`, `l1tex__*`, `dram__*`, opcode counts。 |
| 风险 | H800 L2 容量需本机确认；NCU cache replay 影响行为。 |

### Shared Memory Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | `LDS`, `STS`, `LDSM`, bank conflict, shared staging。 |
| 参考代码 | `gpuwattch-ubench/memories_benchmarks/BE_MEM_SHRD_Acss/`, `accelwattch-ubench/memories_benchmarks/BE_MEM_SHRD_Acss/`。 |
| 改造方式 | conflict-free baseline，再加 bank-conflict variants；tensor-style shared layouts for `LDSM`。 |
| 记录指标 | shared load/store counts、bank conflict metrics if available、power。 |
| 风险 | shared memory 与 tensor pipeline overlap。 |

### Register Pressure Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | register file activity、occupancy/static interaction。 |
| 参考代码 | `.agents/library/benchmarks/accelwattch-ubench/functional_benchmarks/REG_FILE/`。 |
| 改造方式 | 控制 registers per thread，观察 occupancy 和 power；不把它直接当 opcode energy。 |
| 记录指标 | registers/thread、occupancy、local spill、power。 |
| 风险 | 编译器重排、spill 到 local memory。 |

### Atomic / Reduction Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | reduction、warp shuffle、shared reduction、atomic if operators use them。 |
| 参考代码 | FlashMLA softmax/combine kernels；需后续补充专用代码。 |
| 改造方式 | `SHFL`, shared reduction, global atomic 分离；从 uniform reduction 起步。 |
| 记录指标 | reduction opcode counts、shared/global ops、power。 |
| 风险 | FlashMLA reduction 可能被 fused/overlapped。 |

### Instruction Mix Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | 验证线性叠加、pipeline overlap 和 solver robustness。 |
| 参考代码 | `gpuwattch-ubench/mix_benchmarks/`, `accelwattch-ubench/mix_benchmarks/`。 |
| 改造方式 | 构造 ALU+memory、tensor+softmax、load+dequantization mix。 |
| 记录指标 | residual、predicted vs measured。 |
| 风险 | 不应早于 base opcode table 过多引入。 |

### Kernel Launch Overhead Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | 短 operator 或 multi-kernel combine 的 launch/CPU sync overhead。 |
| 参考代码 | FlashMLA benchmark/tests，Nsight Systems。 |
| 改造方式 | 空 kernel/NOP kernel/short loop，多次 launch 放大。 |
| 记录指标 | Nsys kernel launch trace、operator runtime、NVML window。 |
| 风险 | NVML 采样粒度远大于单 kernel。 |

### FlashMLA / GEMM / FA3 Operator Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | 真实 operator power ground truth 和 SASS top-k。 |
| 参考代码 | `.agents/library/operators/FlashMLA/benchmark/bench_flash_mla.py`, FlashMLA tests。GEMM/FA3 来源待补。 |
| 改造方式 | Phase 1 只做 profiling；Phase 4 单独做 power ground truth；统一日志和 shape config。 |
| 记录指标 | kernel list、runtime、SASS counts、cache/tensor metrics、power trace。 |
| 风险 | operator launches 多 kernel；benchmark harness 可能含 CPU/Python overhead。 |

### Sparse Memory Access Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | FlashMLA sparse indices、topk、irregular KV gather。 |
| 参考代码 | `.agents/library/operators/FlashMLA/tests/lib.py`, sparse decode/prefill tests。 |
| 改造方式 | random/contiguous/page-local indices；invalid ratio；topk sweep。 |
| 记录指标 | L2/HBM hit rate, branch/predicate counts, address ALU counts。 |
| 风险 | locality distribution 决定 power；必须记录 seed 和 index distribution。 |

### Power Sampling Benchmark

| 项 | 设计 |
| --- | --- |
| 目标 | 验证 NVML sampling、energy counter、repeatability。 |
| 参考代码 | 本项目后续 `src/power`，AccelWattch paper measurement flow。 |
| 改造方式 | idle、active-no-op、stable ALU、stable HBM 四类基准。 |
| 记录指标 | median power、CV、temperature drift、clock drift、energy integration error。 |
| 风险 | 无法锁频、其他进程、thermal/power cap。 |

## First H800 Microbenchmark Suite

按优先级执行：

1. `baseline_idle_h800`, `baseline_active_noop_h800`, `baseline_nop_loop_h800`
2. `alu_iadd3_u32`, `alu_imad_u32`, `alu_lop3_u32`, `alu_mov_u32`
3. `fp_fadd_f32`, `fp_fmul_f32`, `fp_ffma_f32`
4. `ctrl_isetp_uniform`, `ctrl_bra_uniform`
5. `gmem_ldg_u64_l1hit`, `gmem_ldg_u64_l2hit`, `gmem_ldg_u64_dram`
6. `gmem_stg_u64_stream`
7. `smem_lds_u64`, `smem_sts_u64`, `smem_ldsm_tensor_layout`
8. `tensor_wgmma_bf16_m64n64k16` 或实际 FlashMLA top-k tensor opcode shape
9. `async_mbarrier_arrive_wait`, `async_ldgsts_or_tma_copy` if emitted
10. `flashmla_sparse_index_gather`, `flashmla_fp8_dequant`

## 验收标准

一个 microbenchmark 进入训练集前必须满足：

- target SASS opcode 可见；
- opcode count 随 iterations 线性；
- energy mode 稳态窗口足够长；
- repeated-run variance 在协议阈值内；
- clock/temperature/power limit 无异常；
- memory hit/miss 行为与设计一致；
- raw power trace、summary、SASS dump、NCU report、metadata 都可追溯。
