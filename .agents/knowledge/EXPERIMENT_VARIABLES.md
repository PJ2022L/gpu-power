# Experiment Variables

本文件统一 H800 上 FlashMLA、GEMM、microbenchmark 和 power-specific 扫参变量。每个变量都说明影响、为什么影响功耗、推荐扫参和混杂因素。

## 来源

- `.agents/library/operators/FlashMLA/README.md`
- `.agents/library/operators/FlashMLA/tests/lib.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_dense_decoding.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_decoding.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_prefill.py`
- `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md`
- `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md`
- `.agents/library/benchmarks/gpuwattch-ubench/`
- `.agents/library/benchmarks/accelwattch-ubench/`

## FlashMLA Variables

| 变量 | 影响什么 | 为什么影响功耗 | 推荐扫参范围 | 混杂因素 |
| --- | --- | --- | --- | --- |
| `batch size / b` | active SM、L2/HBM traffic、scheduler balance | 请求越多并行度和 working set 越大 | `1,2,6,64,128,148` 起步 | varlen、zero length、GPU memory |
| `s_q` | compute intensity、softmax/reduction、grid shape | dense 文档指出 `h_q*s_q` 影响 compute/memory bound | decoding `1,2,4`; sparse prefill `62,213,1024,4096` | MTP/decoding/prefill 语义不同 |
| `h_q` | Tensor Core work、output/register pressure | query heads 决定 QK/PV FLOPs 和 accumulators | `64,128`; correctness 可含 `1,3,9,63,126` | `h_q % h_kv` 约束 |
| `h_kv` | KV reuse、MQA/MHA 模式 | MQA 中多个 Q heads 共享 KV | H800 FlashMLA sparse 先 `1`; dense 可 `1,2,3,8` | sparse decode API 要求可能更严格 |
| `head dim / d_qk` | QK FLOPs、KV bytes、register/shared | 512/576 对 FP8 layout 和 WGMMA shape 不同 | `512,576` | dtype、RoPE/noPE layout |
| `latent dim / d_v` | PV FLOPs、output bytes | V dimension 决定 output accumulator size | `512` 起步 | API 约束，文档中 d_v 常为 512 |
| `sequence/context length / s_kv` | KV bytes、QK/PV FLOPs | attention length 主导 decoding work | `4096,8192,16384,32768,65536,98304,131072` | HBM 容量、L2 locality |
| `block/page size` | block table、coalescing、metadata | paged KV layout 影响 address calc 和 cache | `64` baseline | dense decode API 要求 page block size 64 |
| `num blocks` | block_table size、scheduler | block 数影响 metadata 和 split | derived from `s_kv/block_size` | varlen padding |
| `sparse ratio` | selected KV fraction | sparse 直接减少 QK/PV 和 KV load | 用 `topk/s_kv` 记录 | indices locality |
| `top-k blocks/tokens` | sparse QK/PV、index load | sparse decoding/prefill 主变量 | `128,256,512,1024,2048,4096,8192,16384,32768` | invalid indices、topk_length |
| `dtype` | Tensor Core path、bytes、dequantization | BF16/FP16/FP8 指令和 memory bytes 不同 | BF16 dense; FP8 sparse KV | actual SASS path |
| `cache layout` | memory coalescing、dequantization | FP8 KV cache layout V32/MODEL1 不同 | FlashMLA default layouts | quant/dequant correctness |
| `causal` | mask/control/predicate | 增加 predicate、branch、softmax masking | `false,true` | sequence shape |
| `prefill / decoding` | kernel structure | prefill large `s_q`; decoding small `s_q` | 分开建模 | 不能混作同一 operator |
| `dense / sparse` | memory/control/tensor balance | sparse 引入 indices 和 irregular access | dense, sparse | topk 和 locality |
| `split-k / split-kv` | combine kernel、launch count | 分裂增加 reduction/combination | `num_splits` from metadata | scheduler decisions |
| `split-head strategy` | CTA/head mapping | 影响 active SM 和 DSM crossover | 根据 FlashMLA kernel | 源码内部策略 |
| `num warps` | occupancy、issue mix | 影响 active lanes 和 scheduling | 从 kernel metadata 记录 | 手写 kernel 不一定可调 |
| `num CTAs` | active SM/static power | 决定并行度和 saturation | 由 shape/scheduler 得出 | load balance |
| `shared memory usage` | occupancy、LDS/STS/LDSM | shared staging 和 bank conflicts | 记录 per kernel | dynamic allocation |
| `register usage` | occupancy、spills、static | FlashMLA output accumulators register-heavy | 记录 registers/thread | compiler version |

## GEMM Variables

GEMM 来源待补到 `.agents/library/operators/`，本表先定义 H800 需要记录的变量。

| 变量 | 影响什么 | 为什么影响功耗 | 推荐扫参范围 | 混杂因素 |
| --- | --- | --- | --- | --- |
| `M` | output rows、parallelism | 决定 tiles 和 active SM | small/medium/large，覆盖 underfill 和 saturation | cublasLt kernel selection |
| `N` | output cols、parallelism | 决定 tiles 和 memory reuse | 同 `M` | layout |
| `K` | arithmetic intensity | 大 K 更 compute-bound，小 K overhead 更高 | small-K 和 large-K | split-k |
| `dtype` | Tensor Core path | BF16/FP16/FP8/TF32 指令不同 | BF16/FP16/FP8 if supported | math mode |
| `layout` | coalescing/cache | row/col/transposed 影响 loads | NN/NT/TN/TT | library kernel selection |
| `tile size` | tensor shape、shared memory | 决定 WGMMA/HGMMA shape 和 occupancy | 从 SASS/kernel metadata 反推 | not always controllable |
| `Tensor Core path` | opcode table | GEMM 主体可能是 WGMMA/HGMMA | record actual SASS | fallback SIMT path |
| `split-k` | reduction/atomic/combine | 增加 extra kernel 或 reductions | off/on, split count | library heuristic |
| `batch GEMM` | launch/parallelism | 小矩阵批处理改变 overhead | batch `1,8,64,128` | memory layout |
| `small-K / large-K` | compute/memory/overhead | small-K 更受 launch/shared setup 影响 | include both | chosen kernel |
| `L2 reuse` | memory energy | repeated A/B tile reuse 降低 HBM | vary M/N/K and stride | cache residency |
| `memory stride` | coalescing/cache | 非连续 stride 增加 transactions | contiguous, padded, strided | library may copy/transform |

## Microbenchmark Variables

| 变量 | 影响什么 | 为什么影响功耗 | 推荐扫参范围 | 混杂因素 |
| --- | --- | --- | --- | --- |
| `target opcode` | energy table column | 每个 opcode 是 unknown `x_i` | 来自 operator SASS top-k | compiler may not emit |
| `opcode modifier` | grouping/scaling | cache/evict/data width/predicate modifier 可能改能耗 | preserve raw modifier | NCU metric support |
| `iterations` | runtime/steady state | power sampling 需要长窗口 | tune to 180s baseline | counter scaling |
| `unroll factor` | loop overhead | 高 unroll 提高 target opcode fraction | `16,32,64,100` | code size/register pressure |
| `grid dim` | active SM | static power 和 saturation | >= all SM, oversubscribe 2x | H800 SM 数需本机确认 |
| `block dim` | active lanes/occupancy | 影响 warp/lane saturation | `128,256,512` | registers/shared |
| `active lanes` | divergence/static | lane-level power gating/issue | `32` first; then `1,4,8,16,24` | branch mix |
| `active SM count` | static correction | operator 可能 underfill | all-SM first, then sweep | block scheduling not exact |
| `dependency chain` | latency vs throughput | dependent ops serialize pipeline | independent chains first | register pressure |
| `data width` | memory instruction energy | 32/64/128-bit loads/stores differ | `32,64,128` | vectorization |
| `working set size` | L1/L2/HBM hit | cache hierarchy 分摊 | below L1, between L1-L2, above L2 | H800 cache size unknown |
| `stride/locality` | coalescing/cache | affects transactions and L2 hit | contiguous, stride, random | address ALU |
| `shared bank pattern` | shared stalls | bank conflict changes cycles/power | conflict-free first | compiler layout |
| `tensor shape` | WGMMA opcode | shape determines emitted tensor op | start from operator top-k | CUTLASS heuristics |
| `barrier frequency` | sync overhead | mbarrier/barrier energy | per tile/loop sweep | deadlock/correctness |
| `cluster size` | DSM/st.async | Hopper cluster behavior | `1,2` first | launch support |

## Power-specific Variables

| 变量 | 影响什么 | 为什么影响功耗 | 推荐记录/扫参 | 混杂因素 |
| --- | --- | --- | --- | --- |
| GPU clock | dynamic power/runtime | `P ~ f,V`，runtime 也变 | lock or record SM clock | DVFS, permission |
| memory clock | HBM power/bandwidth | memory-bound power sensitive | lock or record | power cap |
| power limit | throttling/peak | cap 会改变 clocks | fixed per session | cluster policy |
| temperature | static leakage | temp changes static power | start/drift thresholds | cooling |
| voltage | dynamic/static | often not directly controlled | record if exposed | hidden DVFS |
| occupancy | active resources | affects static and latency hiding | record per kernel | registers/shared |
| instruction mix | dynamic energy | model feature | SASS opcode counts | profiler overhead |
| SM utilization | saturation | low util makes static dominate | NVML/NCU | sampling granularity |
| Tensor Core utilization | tensor path | WGMMA/HGMMA contribution | NCU tensor metrics | overlap |
| memory bandwidth | HBM energy | memory dynamic energy | DRAM bytes/time | cache |
| L2 hit rate | hierarchy split | L2 vs HBM energy differs | NCU metrics | replay effects |
| HBM traffic | memory energy | bytes dominate memory-bound | DRAM sectors/bytes | compression/ECC |
| kernel duration | energy integration | short kernels hard to measure | loop amplify | launch overhead |
| repetition count | uncertainty | CV needs repeats | >=5 official | time cost |

## 推荐实验矩阵

### MVP

1. Fixed clock/power policy。
2. idle + active-no-op baseline。
3. HBM bandwidth sweep: working set and width。
4. Tensor WGMMA benchmark: one BF16 shape。
5. L2-sensitive benchmark。
6. GEMM dense tensor path。
7. FlashMLA dense decoding。

### Phase 2 扩展

1. FP8 sparse decoding: topk sweep。
2. FP8 dequantization benchmark。
3. sparse index/gather benchmark。
4. DSM/st.async/barrier benchmark。
5. sparse prefill large `s_q` benchmark。

## 记录规范

每个 experiment config 必须保存：

- variables JSON/YAML；
- shape id；
- operator/benchmark command；
- random seed；
- data layout；
- dtype；
- expected target SASS；
- actual SASS summary；
- power policy；
- baseline id。
