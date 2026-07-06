# Paper Notes

本文件按来源逐篇整理与 H800 功耗建模直接相关的知识。每条结论都标注 `.agents/library/...` 来源。本轮以 Wattchmen 为主线；AccelWattch 只作为公开 microbenchmark、测量和组件级建模参考。

## Wattchmen

**来源**: `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`; 辅助定位笔记 `.agents/library/papers/wattchmen/01-paper-summary.md`, `.agents/library/papers/wattchmen/02-modeling-method.md`, `.agents/library/papers/wattchmen/03-microbenchmark-design.md`, `.agents/library/papers/wattchmen/04-measurement-protocol.md`

### 研究目标

Wattchmen 目标是从真实 GPU 测量中构建高保真、可迁移的每条 SASS 指令动态能耗表，并用该表预测应用能耗。它强调应用优化所需的细粒度 attribution，而不是只给出整卡平均功耗。

对 H800 项目的直接含义：复现目标应是 H800 上的 SASS-level energy table，而不是复刻 V100/A100/H100 的数值。

### 建模对象

- SASS opcode 及部分 modifier。
- Memory instruction 的数据宽度与 cache hierarchy hit/miss 行为。
- 训练 microbenchmark 的 power/energy trace、runtime、SASS opcode counts、cache hit rates。
- 预测 workload 的 runtime、SASS opcode counts、cache hit rates。

来源依据：Wattchmen 论文 Section 3 说明训练阶段使用 microbenchmark、profiler 信息、steady-state energy measurement 来创建 per-instruction energy table；预测阶段结合 instruction counts 和 cache hit rates。

### 功耗拆分方式

Wattchmen 使用：

```text
E_total = E_const + E_static + E_dynamic
```

- `E_const`: GPU 低功耗/idle 状态也存在的固定能量。
- `E_static`: kernel active 时共享资源被上电但不一定 switching 的能量，随 active SM/thread policy 变化。
- `E_dynamic`: 指令执行和 memory hierarchy activity 的动态能量。

H800 首版应独立测 idle baseline 和 active-no-op baseline，不能复制其他 GPU 的 constant/static 数值。

### Microbenchmark 方法

Wattchmen 的关键不是“为每条指令做完美孤立 benchmark”，而是让所有 benchmark 构成线性方程组。一个 benchmark 的 address arithmetic、load/store、branch、move 等 ancillary instructions 在另一个 benchmark 中会成为主目标，从而被统一归因。

设计重点：

- 使用 inline assembly / source pattern / loop unroll 增大目标 SASS opcode 占比。
- 必须通过 SASS dump 和 profiler 确认实际 opcode，而不能相信 PTX 名称。
- 需要覆盖 compute、control flow、memory hierarchy。
- memory benchmark 要覆盖数据宽度、L1/L2/DRAM 行为。
- H100/Hopper 评估遇到新的 warp-group matrix multiply 指令，coverage 不足会导致 direct model error，bucketing 可提升 coverage。

H800 直接扩展：必须为 WGMMA/HGMMA、LDSM、LDGSTS/TMA、mbarrier、cluster/DSM 相关路径保留 benchmark 计划。

### 采集指标

训练输入至少包括：

- power trace 或 energy counter；
- runtime；
- SASS opcode counts；
- cache hit/miss behavior；
- GPU clocks、power limit、temperature、utilization；
- benchmark iterations、unroll、grid/block。

Wattchmen 论文使用 NVML 作为 hardware ground truth，同时指出 NVML granularity 对短 kernel 不友好，因此 energy run 需要长稳态窗口。

### Measurement noise 处理

Wattchmen 采用长时间 steady-state energy measurement。论文报告的配置包括每个 microbenchmark 5 次重复、每次约 180 秒、结束后约 60 秒 cooldown。它还把 profiler 运行和 energy 运行分开，避免 profiler overhead 影响功耗 ground truth。

H800 项目应保留这一 baseline，并加入 repeated-run 方差阈值作为 validity gate。

### 模型形式

动态能量线性系统：

```text
A x = b
```

- `A`: 每个 microbenchmark 的 SASS instruction counts。
- `x`: unknown per-instruction dynamic energy。
- `b`: 扣除 constant/static 后的 measured dynamic energy。

求解应使用 non-negative constrained solver。Wattchmen 论文强调残差监控和 coverage 扩展，包括 direct、prediction/grouping/bucketing。

### 对本项目可复用

- 训练/预测两阶段结构。
- SASS 级 opcode table。
- ancillary instructions 进入全局方程组。
- energy run 与 profiler run 分离。
- memory instruction 按 hierarchy hit/miss 分摊。
- long steady-state measurement。
- 对 unknown/new Hopper opcodes 使用 grouping/scaling/bucketing，但必须标注 approximate。

### 不适用或需改造

- 论文中的 V100/A100/H100 energy table 不适用于 H800。
- 论文未覆盖 FlashMLA 的具体 sparse decoding/prefill kernel。
- 论文默认 single-GPU，不覆盖 NVLink/NVSwitch collective power。
- 论文的 all-SM/all-lane training policy 对低 occupancy operator 可能有误差，需要 H800 后续 occupancy/static 修正。

### 需要进一步验证

- H800 上 NVML energy counter 是否可用，采样粒度和积分误差。
- H800 active-no-op baseline 是否稳定。
- SM90 WGMMA/HGMMA opcode metric 是否可由当前 NCU 版本完整导出。
- FlashMLA kernels 是否稳定 emit TMA、mbarrier、st.async、WGMMA/HGMMA 指令，以及是否随 CUDA 12.8/12.9 变化。

## AccelWattch

**来源**: `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`; 辅助笔记 `.agents/library/papers/accelwattch-reference/accelwattch-reference.md`; 代码来源 `.agents/library/benchmarks/accelwattch-ubench/`

### 研究目标

AccelWattch 是一个面向现代 GPU 的 configurable component-level power model。它可由 simulation、hardware counters 或 hybrid data 驱动，目标是 cycle-level 或 component-level power estimation。

对本项目的边界：AccelWattch 不是最终复现目标，因为本项目目标是 Wattchmen 风格的 H800 SASS instruction energy table。

### 建模对象

- constant power；
- static power；
- dynamic power；
- microarchitectural components；
- power gating、DVFS、thread divergence、active SM/lane；
- PTX/SASS 到 component 的 mapping；
- hardware counters 或 Accel-Sim statistics。

### Microbenchmark 方法

AccelWattch 论文报告使用约 102 个 microbenchmark 来校准动态功耗，并结合 quadratic programming。开源目录中有：

- `functional_benchmarks/`: FP/INT/SFU/MOV/REG_FILE；
- `branching_benchmarks/`: active lanes/divergence；
- `memories_benchmarks/`: L1/L2/DRAM/shared/constant/texture；
- `static_power_modeling/`: active/static power；
- `tensor_benchmarks/`: WMMA tensor benchmark。

这些代码可作为 H800 microbenchmark 重写参考，但必须重新面向 SM90 SASS 验证。

### Measurement noise 处理

AccelWattch 强调 power profiling 时目标 GPU 不应运行其他程序。论文中还讨论了温度、频率、DVFS 和 static power 的影响。它使用 NVML/nvidia-smi 进行硬件功耗测量，并用 Nsight Compute 验证 benchmark 行为。

H800 项目可复用这些测量工程实践，但不能采用其 Volta component scaling 数值。

### 模型形式

AccelWattch 使用 quadratic programming/optimization 调整 component-level scaling factors。其输出是 component power breakdown，而不是 per-SASS energy table。

### 对本项目可复用

- microbenchmark 分类；
- active SM/lane/static baseline 设计；
- L1/L2/DRAM pointer chasing 与 inline PTX memory path；
- WMMA/tensor benchmark 的原型；
- 独占 GPU、频率/温度控制、NVML 测量和 Nsight Compute 验证流程。

### 不适用或需改造

- quadratic programming 组件模型不是本项目目标。
- Volta GV100 microbenchmark 数值和 component map 不能用于 H800。
- 旧 WMMA benchmark 不能覆盖 H800 WGMMA/HGMMA/TMA。
- 部分代码使用旧 CUDA helper 或固定 grid/block，需现代化。

## NVIDIA Hopper/H100 Whitepaper

**来源**: `.agents/library/docs/nvidia-h100-tensor-core-hopper-whitepaper.pdf`

### 与 H800 相关的架构机制

H800 属 Hopper 系列，因此以下机制对 H800 复现有参考价值：

- Hopper SM 的 Tensor Core 和 FP8/BF16/FP16 路径；
- thread block cluster；
- Distributed Shared Memory；
- Tensor Memory Accelerator；
- asynchronous transaction barrier；
- HBM/L2 memory hierarchy；
- fourth-generation NVLink/NVSwitch 作为多 GPU 背景。

注意：白皮书针对 H100。H100 的 SM 数、L2 大小、HBM 带宽、TDP、NVLink 带宽等数值不能直接写成 H800 实验事实。

### 对本项目可复用

- 解释 FlashMLA dense decoding 中 TMA copy-GEMM pipelining 的架构基础。
- 解释 FlashMLA FP8 sparse decoding 中 CTA cluster/DSM/st.async/barrier 的架构基础。
- 指导 microbenchmark 增加 TMA、mbarrier、cluster、WGMMA/HGMMA 家族。

## PTX ISA 9.0

**来源**: `.agents/library/docs/ptx_isa_9.0.pdf`

### 与 H800 相关的 ISA 机制

PTX ISA 9.0 包含对 SM90+ 相关机制的描述：

- cluster-level execution 和 special registers；
- `.shared::cluster` state space；
- `st.async`；
- asynchronous copy；
- `tensormap`；
- `barrier.cluster`；
- `mbarrier`；
- `wgmma.mma_async` 和 sparse variants；
- `ldmatrix`/matrix load-store 相关机制。

### 对本项目可复用

用于 microbenchmark 的 PTX 诱导、kernel 结构理解和 SASS opcode mapping。但最终训练仍必须以实际 SASS 和 NCU counters 为准。

## Nsight Compute / Nsight Systems / Binary Utilities

**来源**: `.agents/library/docs/nsight-compute.pdf`, `.agents/library/docs/nsight-systems.pdf`, `.agents/library/docs/CUDA_Binary_Utilities.pdf`

### Nsight Compute

用途：

- kernel-level profiling；
- SASS opcode metrics；
- cache/memory metrics；
- report/export；
- NVTX 过滤；
- metric availability query。

注意：NCU profiling runtime 不能作为 power ground truth。

### Nsight Systems

用途：

- operator call path timeline；
- multi-kernel operator 聚合；
- CUDA API/kernel launch trace；
- NVTX range 到 GPU kernel 的映射；
- SQLite/export 后处理。

### CUDA Binary Utilities

用途：

- `cuobjdump --dump-sass`；
- `nvdisasm`；
- 检查 binary 是否发出预期 SASS opcode。

## FlashMLA Documents

**来源**: `.agents/library/operators/FlashMLA/README.md`, `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md`, `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md`, `.agents/library/operators/FlashMLA/tests/*.py`, `.agents/library/operators/FlashMLA/csrc/api/*.h`

### 与 H800 功耗建模的关键事实

- FlashMLA 支持 SM90 dense decoding、SM90 sparse decoding、SM90 sparse prefill。
- README 报告 H800 SXM5 CUDA 12.8 上 dense decoding 可达 3000 GB/s memory-bound、660 TFLOPS compute-bound；sparse decoding 可达 410 TFLOPS；sparse prefill 可达 640 TFLOPS。这些是项目来源声明，需本机确认。
- Dense decoding 使用 MQA，典型 `h_q=128`, `h_kv=1`, `d_k=576`, `d_v=512`。
- FP8 sparse decoding KV cache 每 token 656 bytes：512 FP8 values、4 FP32 scales、64 BF16 RoPE values。
- Dense decoding deep dive 提到 seesaw scheduling、online softmax、TMA copy-GEMM pipelining、cache hint、programmatic dependent launch、tile scheduler。
- Sparse FP8 deep dive 提到 dequantization-bound、CTA cluster size 2、DSM、`st.async`、cluster transaction barrier。

### 对本项目可复用

FlashMLA 是 operator-level validation 目标，同时也是 microbenchmark target 的来源。NCU top-k SASS 应优先围绕 FlashMLA kernels 出现的 WGMMA/HGMMA、TMA/LDGSTS、mbarrier、LDSM、global load/store、shared load/store、conversion/dequantization、softmax/reduction/control-flow opcode 构建。
