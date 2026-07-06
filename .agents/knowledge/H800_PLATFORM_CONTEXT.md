# H800 Platform Context

本文件记录 H800 复现实验需要的 Hopper/H800 平台上下文。原则：Hopper/H100 文档可提供架构机制，但 H800 具体规格必须本机确认，不能用 H100/B200 数值直接替代。

## 来源

- `.agents/library/docs/nvidia-h100-tensor-core-hopper-whitepaper.pdf`
- `.agents/library/docs/ptx_isa_9.0.pdf`
- `.agents/library/docs/CUDA_Binary_Utilities.pdf`
- `.agents/library/docs/nsight-compute.pdf`
- `.agents/library/operators/FlashMLA/README.md`
- `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md`
- `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md`

## 实验目标边界

- 目标 GPU：H800 系列，优先 SXM/HGX 环境。
- 目标架构：Hopper/SM90。
- 目标容器：`operatorsforge:h800-v1.0`，container name `l2_mla_study`。
- 目标算子：GEMM、FlashMLA、FlashAttention v3。
- 本轮不以 H100、B200、Blackwell 为实验目标。

## Hopper 可迁移机制

以下机制来自 Hopper/H100 whitepaper 和 PTX ISA，可作为 H800 microbenchmark 与 FlashMLA 拆解参考：

| 机制 | 来源 | H800 项目含义 |
| --- | --- | --- |
| Fourth-generation Tensor Cores | `.agents/library/docs/nvidia-h100-tensor-core-hopper-whitepaper.pdf` | GEMM/FlashMLA 的 tensor path 需要 WGMMA/HGMMA benchmark。 |
| FP8 support / Transformer Engine 背景 | whitepaper, FlashMLA FP8 docs | Sparse decoding FP8 KV cache 需要 dequantization 和 FP8 load benchmark。 |
| Thread Block Cluster | whitepaper, PTX ISA | Sparse decoding DSM crossover 需要 cluster-aware benchmark。 |
| Distributed Shared Memory | whitepaper, PTX ISA | `st.async`/peer shared memory/cluster barrier 可能影响功耗。 |
| Tensor Memory Accelerator | whitepaper, PTX ISA | Dense decoding TMA copy-GEMM pipelining 需要 async copy/TMA benchmark。 |
| Asynchronous Transaction Barrier / `mbarrier` | whitepaper, PTX ISA | TMA/DSM 同步开销要单独覆盖。 |
| `.shared::cluster` state space | PTX ISA | sparse decoding cluster shared memory 相关。 |
| `wgmma.mma_async` | PTX ISA | SM90 tensor core 指令诱导参考；最终以 SASS 为准。 |
| `ldmatrix` / matrix loads | PTX ISA | WGMMA operand loading和 `LDSM` SASS 相关。 |
| HBM/L2 hierarchy | whitepaper | memory hierarchy benchmark 需要 L1/L2/HBM 分层。 |
| NVLink/NVSwitch | whitepaper | 多 GPU 背景；本项目单 GPU operator power 首版不建模。 |

## FlashMLA 报告的 H800 信息

这些来自 FlashMLA 文档，可用于初始实验设计，但必须在本机确认。

| 信息 | 来源 | 使用方式 |
| --- | --- | --- |
| Dense MLA decoding 在 H800 SXM5 CUDA 12.8 上可达 3000 GB/s memory-bound | `.agents/library/operators/FlashMLA/README.md` | 选择 memory-bound dense shape 的参考。 |
| Dense MLA decoding 在 H800 SXM5 CUDA 12.8 上可达 660 TFLOPS compute-bound | README | 选择 compute-bound dense shape 的参考。 |
| Sparse MLA decoding 在 H800 SXM5 CUDA 12.8 上可达 410 TFLOPS | README, FP8 sparse deep dive | sparse decoding validation 目标参考。 |
| Sparse MLA prefill 在 H800 SXM5 CUDA 12.8 上可达 640 TFLOPS | README | sparse prefill validation 目标参考。 |
| Dense deep dive 使用 H800 SXM5 peak bandwidth 3.35 TB/s、peak FLOPs 990 TFLOPS、throttled practical peak 865 TFLOPS | `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md` | 只作为 FlashMLA 作者环境报告值，需本机确认。 |
| FP8 sparse deep dive 用 `989 TFLOPS / 1830 MHz / 132 SMs` 估算 per-SM MMA throughput | `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md` | 只作为作者环境估算，H800 本机必须确认 SM 数、clock、实际 clocks。 |

## H800 需本机确认字段

| 字段 | 为什么重要 | 采集命令 |
| --- | --- | --- |
| GPU name / SKU / UUID | 确认 H800 型号和实验对象 | `nvidia-smi -i <GPU_ID> --query-gpu=index,uuid,name,serial --format=csv` |
| SM count | grid/block saturation、per-SM throughput | CUDA `deviceQuery` 或小程序 `cudaGetDeviceProperties`; NCU system info |
| HBM capacity | FlashMLA long context、working set | `nvidia-smi -i <GPU_ID> --query-gpu=memory.total --format=csv` |
| HBM memory clock / bandwidth | HBM benchmark 和 power | `nvidia-smi -q -i <GPU_ID> -d CLOCK,MEMORY`；实测 bandwidth benchmark |
| L2 cache size | L2 hit/miss working set | CUDA device attributes if exposed; NCU device info; vendor docs if available |
| max shared memory per SM/CTA | shared/TMA/WGMMA benchmark | CUDA device attributes |
| registers per SM | FlashMLA occupancy、dense decoding register pressure | CUDA device attributes / NCU |
| supported SM/memory clock ranges | lock frequency policy | `nvidia-smi -i <GPU_ID> -q -d SUPPORTED_CLOCKS` |
| default/current power limit | power cap 控制 | `nvidia-smi -i <GPU_ID> -q -d POWER` |
| NVML energy counter support | energy integration | run NVML sampler; check `nvmlDeviceGetTotalEnergyConsumption` |
| NCU SASS opcode metric availability | instruction counts | `ncu --query-metrics | grep sass__inst_executed` |
| WGMMA/HGMMA SASS naming | tensor energy table key | `cuobjdump --dump-sass`, NCU opcode metrics |
| TMA/LDGSTS/mbarrier SASS naming | async copy/sync benchmark | `cuobjdump --dump-sass`, NCU opcode metrics |
| MIG/MPS state | isolation and SM partition | `nvidia-smi -i <GPU_ID> -q | grep -E 'MIG|MPS'` |

## 推荐本机采集脚本片段

```bash
GPU_ID=${GPU_ID:-0}

nvidia-smi -i "${GPU_ID}" \
  --query-gpu=index,uuid,name,driver_version,persistence_mode,power.limit,power.draw,clocks.sm,clocks.mem,clocks.max.sm,clocks.max.memory,temperature.gpu,utilization.gpu,memory.total,memory.used \
  --format=csv

nvidia-smi -q -i "${GPU_ID}" -d POWER,CLOCK,SUPPORTED_CLOCKS,MEMORY,UTILIZATION,TEMPERATURE
nvidia-smi --query-compute-apps=gpu_uuid,pid,process_name,used_memory --format=csv
ncu --query-metrics | grep -E 'sass__inst_executed|l1tex__|lts__|dram__' | head -200
```

CUDA device properties should be collected by a small compiled helper inside the H800 container and stored with each experiment.

## H800 初始建模假设

V1 允许假设：

- H800 follows Hopper/SM90 ISA family for WGMMA/TMA/cluster features。
- FlashMLA SM90 kernels are relevant to H800。
- All official operator power validation is single-GPU。
- Clock/power/temperature are controlled or recorded。

V1 不允许假设：

- H100 SM count equals H800 SM count。
- H100 L2 size/HBM bandwidth/power limit equals H800。
- FlashMLA README performance numbers equal local measurements。
- B200/SM100 kernel behavior is relevant to H800 power model。
- NVML energy counter is available until checked。

## H800 microbenchmark implications

### SM saturation

All-SM training requires knowing actual SM count. Until confirmed, benchmark config should use runtime query rather than hard-coded block count.

### Memory hierarchy

L1/L2/HBM benchmark working sets must be generated from confirmed L2/HBM capacity. Before confirmation, document them as symbolic:

```text
L1-hit working set: per-SM small repeated set
L2-hit working set: >L1 and <confirmed L2
HBM working set: >confirmed L2 with streaming/random access
```

### Tensor Core

FlashMLA dense/sparse kernels may show SASS opcodes named differently from PTX `wgmma.mma_async`. The energy table key must use the SASS opcode string observed on H800.

### TMA / async copy

High-level TMA or CUTE APIs may lower into SASS forms that vary with CUDA version. Every TMA benchmark needs:

- source version；
- compile flags；
- SASS dump；
- NCU opcode metrics；
- cache metrics；
- async barrier metrics if available。

### Sparse decoding cluster behavior

Sparse FP8 docs describe CTA cluster size 2 and DSM crossover. H800 validation must confirm:

- kernel launch uses clusters；
- cluster-related SASS/metrics are visible；
- `st.async` or equivalent peer shared-memory copy appears；
- barrier/mbarrier counts scale with topk or tile count。

## 与 operator profiling 的关系

Phase 1 on H800:

- run GEMM/FlashMLA/FA3 under NCU/Nsys；
- collect kernel list and SASS top-k；
- do not collect validation power ground truth。

Phase 2:

- generate microbenchmark plan from top-k SASS。

Phase 4:

- collect operator power ground truth with NVML, no NCU。

This separation prevents profiler overhead from contaminating power data.

## 待补 H800 facts 表

| 字段 | 当前状态 | 负责人 |
| --- | --- | --- |
| SM count | 需本机确认 | H800 agent |
| HBM capacity | 需本机确认 | H800 agent |
| HBM measured bandwidth | 需本机确认 | H800 agent |
| L2 size | 需本机确认 | H800 agent |
| clock lock support | 需本机确认 | H800 agent |
| power limit policy | 需本机确认 | H800 agent |
| NVML energy counter support | 需本机确认 | H800 agent |
| NCU opcode metric name | 需本机确认 | H800 agent |
| FlashMLA actual kernel names | 需本机确认 | H800 agent |
