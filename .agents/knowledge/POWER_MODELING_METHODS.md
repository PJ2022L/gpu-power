# Power Modeling Methods

本文件按方法而不是按论文组织，目标是帮助 H800 agent 判断“当前误差来自 microbenchmark 覆盖不足、测量噪声，还是 modeling 假设错误”。

## Wattchmen 类 SASS 指令级建模

**主要来源**: `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`, `.agents/library/papers/wattchmen/*.md`

### 模型

```text
E_total = E_const + E_static + E_dynamic
E_dynamic = sum_i count_i * e_i
A x = b
```

- `count_i`: microbenchmark 或 operator 中执行的 SASS opcode count。
- `e_i`: H800 上待求的 per-instruction dynamic energy。
- `b`: measured energy 中扣除 constant/static 后的 dynamic energy。
- solver: 默认 non-negative least squares 或 constrained linear solver。

### 优点

- 直接对应真实 binary 上执行的 SASS。
- ancillary instructions 不手工扣除，而是进入全局方程组。
- 适合从 microbenchmark 归纳到 GEMM/FlashMLA/FA3。
- 可输出 opcode-level attribution，帮助决定下一批 microbenchmark。

### 风险

- SASS 随 CUDA/nvcc/driver/arch flags 变化。
- NVML granularity 对短 kernel 不友好。
- all-SM/all-lane training 与 operator occupancy 不匹配时，static attribution 会偏。
- WGMMA/TMA/mbarrier 这类 Hopper 指令如果 coverage 低，会导致 operator error 高。

### H800 采用方式

本项目主线采用该方法。H800 首版需先覆盖：

- idle 和 active-no-op baseline；
- INT/FP/control；
- shared/global memory；
- L1/L2/HBM hit/miss；
- Tensor Core WGMMA/HGMMA；
- LDSM、LDGSTS/TMA、mbarrier、cluster/DSM 相关指令。

## AccelWattch 类组件级建模

**主要来源**: `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`, `.agents/library/benchmarks/accelwattch-ubench/`

### 模型

AccelWattch 将功耗分成 constant、static、dynamic，并把指令/统计映射到 microarchitectural components。它通过 microbenchmark、hardware power measurement、performance counters/simulation statistics 和 quadratic programming 调整 component-level power model。

### 优点

- 对 static power、active SM/lane、power gating、DVFS 有细致工程考虑。
- 开源 microbenchmark 目录可复用。
- 可帮助设计 H800 baseline 和 active-SM sweep。

### 不作为主线的原因

- 输出是 component power，而不是 Wattchmen 式 SASS energy table。
- 组件模型依赖架构假设和 scaling factors，H800 不应继承 Volta/H100 数值。
- 对 FlashMLA 这种手写 SM90 kernel，operator-level attribution 更需要 SASS opcode 与 memory behavior。

### H800 采用方式

只借鉴：

- microbenchmark 类别；
- static/constant/dynamic 分解意识；
- active SM/lane sweep；
- memory hierarchy benchmark；
- NVML/NCU 测量实践。

不采用其 quadratic programming component model 作为最终目标。

## Microbenchmark 驱动建模

**来源**: `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`, `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`, `.agents/library/benchmarks/gpuwattch-ubench/`, `.agents/library/benchmarks/accelwattch-ubench/`

### 核心思想

通过人为控制 instruction mix、memory working set、active SM/lane、data type、tensor shape，把复杂算子拆成可测的原子硬件行为。

### H800 benchmark 设计原则

- 每个 benchmark 输出 energy mode 和 profiler mode。
- energy mode 长稳态，不挂 NCU。
- profiler mode 短运行，收 SASS counts 和 cache metrics。
- 每次 compile 后 dump SASS。
- 目标 opcode 占比高，但不要求纯净。
- 混入的 address/branch/load/store 由方程组统一归因。
- 对 memory instruction，必须用 NCU 验证 hit/miss 行为。

### 适用场景

- 建立 H800 instruction energy table。
- 判断 FlashMLA 的 dense/sparse 子阶段功耗来源。
- 对 operator error 做 root cause。

### 风险

- benchmark 太短导致功耗采样无效。
- benchmark SASS 与 operator SASS 不同。
- loop overhead 占比过高。
- cache state 与真实 operator 不同。
- tensor benchmark 测到 operand movement 多于 tensor math。

## Hardware-counter 驱动建模

**来源**: `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`, `.agents/library/docs/nsight-compute.pdf`

### 模型

使用 Nsight Compute / hardware counters 作为特征，例如：

- instruction counts；
- opcode categories；
- SM active cycles；
- tensor pipe utilization；
- L1/L2/HBM sectors/bytes；
- cache hit rates；
- DRAM throughput；
- occupancy；
- branch divergence。

再用线性模型、回归或 correction term 预测 power/energy。

### 对 H800 的价值

- 是 Wattchmen 模型的必要输入，尤其是 SASS counts 和 cache hit rates。
- 可作为 residual correction：当 per-opcode energy table 误差系统性偏高/偏低时，引入 occupancy、SM active、HBM traffic、tensor utilization 修正。

### 风险

- NCU metric availability 随版本变化。
- profiling replay 可能改变 cache 行为。
- counter 与实际 power trace 不是同一运行。
- 不能把 profiler runtime 当 power runtime。

### 采用方式

首版只用 counters 作为 Wattchmen 输入和 validity check；若 operator error >15% 且 microbenchmark residual 低，再考虑加入 counter-driven correction。

## Black-box Regression 建模

**来源**: Wattchmen 和 AccelWattch 论文相关工作讨论；本库未收录单独黑盒 GPU power regression 论文。

### 模型

直接用 shape、runtime、FLOPs、bytes、utilization、counters 等特征训练回归模型预测 power/energy。

### 优点

- 工程上可能快速降低目标 operator 误差。
- 不需要解释每条 SASS 指令。

### 不作为主线的原因

- 难以外推到新 shape、新 kernel、新 CUDA 编译结果。
- 缺少可解释 attribution，不能指导 microbenchmark 扩展。
- 违背本项目复现 Wattchmen 自底向上方法论的目标。

### H800 使用边界

只允许作为 Phase 5 的 correction baseline 或误差诊断对照，不能替代 SASS energy table。

## White-box Analytical 建模

**来源**: `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md`, `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md`, `.agents/library/docs/nvidia-h100-tensor-core-hopper-whitepaper.pdf`

### 模型

从算子公式和硬件上限推导 FLOPs、bytes、arithmetic intensity、compute-bound/memory-bound/control-bound，并估计阶段时间或能耗。

FlashMLA dense decoding 文档给出：

```text
FLOPs ~= 2 * h_q * s_q * s_k * (d_k + d_v)
memory bytes ~= 2 * s_k * d_k
compute-memory ratio ~= 2 * h_q * s_q
```

FlashMLA FP8 sparse decoding 文档给出 dequantization cycles 与 MMA cycles 的对比，指出 H800 上该 kernel 可能 dequantization-bound。

### 优点

- 能解释 shape 为什么改变 bottleneck。
- 能指导 microbenchmark 扫参范围。
- 能帮助判断 operator error 是 memory、tensor、softmax/control 还是 dequantization 引起。

### 风险

- 对实际 power prediction 不够精细。
- 忽略 overlap、pipeline、cache hint、scheduler、launch overhead。
- 来源文档中的 H800 数值属于项目报告值，需本机确认。

### H800 采用方式

作为设计和诊断工具，不单独作为最终功耗模型。用于：

- 选择 dense decoding compute-bound/memory-bound shapes；
- 选择 sparse decoding topk 和 d_qk；
- 判断需要优先 benchmark HBM、Tensor Core、dequantization、DSM/cluster barrier 中哪类行为。

## 方法选择规则

| 情况 | 优先动作 |
| --- | --- |
| Microbenchmark solver residual 高 | 检查 power trace、重复性、opcode counts、cache behavior；不要先改 operator model。 |
| Residual 低但 operator error 高 | 检查 operator SASS coverage、unknown Hopper opcodes、occupancy/static mismatch、memory hit-rate 分摊。 |
| FlashMLA dense memory-bound shape error 高 | 增加 HBM/L2/TMA/global load/store benchmark，验证 cache hint 和 TMA path。 |
| FlashMLA dense compute-bound shape error 高 | 增加 WGMMA/HGMMA、LDSM、softmax/reduction/control benchmark。 |
| Sparse FP8 decoding error 高 | 增加 FP8 load/dequantization/conversion、DSM/st.async、mbarrier、cluster benchmark。 |
| GEMM error 高而 FlashMLA error 低 | 优先检查 GEMM tensor opcode shape、cublasLt/CUTLASS kernel SASS 与 FlashMLA 是否不同。 |
| 所有 operators 系统性偏移 | 检查 idle/static baseline、clock/power limit、temperature drift、NVML integration。 |

## 第一版模型边界

H800 V1 模型假设：

- `P_const` 是同一测量 session 中 idle baseline 的 median power。
- `P_static` 是 active-no-op median power 与 idle median power 的差值，默认使用 all-SM active baseline。
- `E_dynamic` 由 SASS opcode counts 和 memory hierarchy 分摊线性相加。
- 不显式建模 voltage；通过固定或记录 clock/power limit 控制。
- 不显式建模 pipeline overlap；如果 residual 低但 operator error 高，再加入 overlap/correction。
- 不建模 NVLink/NVSwitch collective。

需要人工介入的条件：

- 增加两轮 high-priority microbenchmark 后 operator error 仍 >15%；
- microbenchmark residual 低但 operator error 对某类 shape 系统性偏高/偏低；
- NCU 无法提供关键 opcode/cache metrics；
- H800 无法锁频且 repeated-run variance 长期超阈值；
- FlashMLA kernel SASS 随 build 选项不稳定，导致 energy table 不可复用。
