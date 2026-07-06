# FlashMLA Power Decomposition

本文件把 FlashMLA 拆成可观测、可 microbenchmark、可建模的功耗阶段。本轮只面向 H800/Hopper/SM90：Dense Decoding、Sparse Decoding、Sparse Prefill。Dense MHA Prefill 的 SM100/B200 路径不作为 H800 目标。

## 来源

- `.agents/library/operators/FlashMLA/README.md`
- `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md`
- `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md`
- `.agents/library/operators/FlashMLA/benchmark/bench_flash_mla.py`
- `.agents/library/operators/FlashMLA/tests/lib.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_dense_decoding.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_decoding.py`
- `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_prefill.py`
- `.agents/library/operators/FlashMLA/csrc/api/dense_decode.h`
- `.agents/library/operators/FlashMLA/csrc/api/sparse_decode.h`
- `.agents/library/operators/FlashMLA/csrc/api/sparse_fwd.h`

## H800 目标 kernel 范围

| Kernel 类别 | H800 状态 | 功耗建模优先级 |
| --- | --- | --- |
| Dense MLA Decoding | README 标注 SM90 MQA BF16，H800 目标 | High |
| Sparse MLA Decoding | README 标注 SM90/SM100 MQA FP8 KV cache，H800 目标 | High |
| Sparse MLA Prefill | README 标注 SM90/SM100 MQA，H800 目标 | High |
| Dense MHA Prefill | README 标注 SM100 MHA | 本轮非目标 |

## 主要输入输出

### Dense / Sparse Decoding

来源接口：`get_mla_metadata` 和 `flash_mla_with_kvcache`，见 `.agents/library/operators/FlashMLA/README.md` 与 `.agents/library/operators/FlashMLA/flash_mla/flash_mla_interface.py`。

主要参数：

| 参数 | 含义 | 功耗影响 |
| --- | --- | --- |
| `b` / batch size | 请求数量 | 决定并行度、active SM、L2/HBM working set。 |
| `s_q` | 每个 sequence 的 query tokens | 影响 arithmetic intensity；dense 文档指出 `h_q*s_q` 决定 compute/memory bound。 |
| `s_kv` / `cache_seqlens` | KV cache 长度 | 决定 QK/PV FLOPs 和 KV/HBM traffic。 |
| `h_q` | query heads | 决定 QK/PV compute 和 output/register pressure。 |
| `h_kv` | KV heads | MQA 常见为 1；影响 KV reuse。 |
| `d_qk` | Q/K dimension，常见 512/576 | 影响 QK FLOPs、KV bytes、register/shared memory。 |
| `d_v` | V dimension，常见 512 | 影响 PV FLOPs 和 output write。 |
| `page_block_size` / `block_size` | paged KV block size，dense decode API 要求 64 | 影响 block_table、coalescing、cache behavior。 |
| `block_table` | paged KV 映射 | metadata/global memory access。 |
| `indices` | sparse token-level selection | sparse index load、irregular HBM/L2、topk 控制。 |
| `topk` | sparse selected tokens | sparse compute/memory 主变量。 |
| `is_fp8_kvcache` | 是否 FP8 KV cache | 引入 FP8 load、scale load、dequantization、conversion。 |
| `causal` | causal mask | control/predicate/softmax 行为。 |
| `tile_scheduler_metadata`, `num_splits` | scheduler metadata | split-kv/combine kernel 数量、load balance、launch overlap。 |

返回值：

- `out`: attention output。
- `lse`: log-sum-exp。
- sparse prefill 还返回 `max_logits`。

### Sparse Prefill

来源接口：`flash_mla_sparse_fwd(q, kv, indices, sm_scale, d_v=512)`。

主要参数：

| 参数 | 含义 | 功耗影响 |
| --- | --- | --- |
| `s_q` | query token 数 | 影响 grid、softmax/reduction、QK/PV FLOPs。 |
| `s_kv` | KV token 数 | sparse selection 范围。 |
| `topk` | 每个 query 关注的 tokens | 主导 sparse QK/PV 和 index load。 |
| `h_q` | query heads，测试中常见 64/128 | 决定 tensor workload 与 output size。 |
| `h_kv` | KV heads，通常为 1 | MQA reuse。 |
| `d_qk` | 512/576 | 影响 QK/PV compute、memory bytes。 |
| `indices` | `[s_q,h_kv,topk]` | sparse metadata 和 irregular access。 |
| `have_attn_sink`, `have_topk_length` | optional features | 增加 predicate/control、额外 metadata load。 |

## Dense Decoding 计算流程

来源 `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md`。

1. Load Q。
2. Load KV blocks through paged cache mapping。
3. Use TMA copies to stage K/V blocks into shared memory。
4. QK matrix multiply using Tensor Core path。
5. Online softmax: running max、rescale、exp、sum。
6. PV matrix multiply。
7. Accumulate output in registers。
8. SplitKV/combine if needed。
9. Write output and LSE。

Dense deep dive 给出近似：

```text
FLOPs ~= 2 * h_q * s_q * s_k * (d_k + d_v)
memory bytes ~= 2 * s_k * d_k
compute-memory ratio ~= 2 * h_q * s_q
```

README/docs 报告 H800 SXM5 上可达 3000 GB/s memory-bound 和 660 TFLOPS compute-bound；这些数值需本机确认。

## Sparse Decoding 计算流程

来源 `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md`。

1. Load Q。
2. Load sparse `indices`。
3. Compute page/block token addresses。
4. Load FP8 KV cache token data。
5. Load FP32 scales 和 BF16 RoPE。
6. Dequantize FP8 NoPE part to BF16。
7. Use CTA cluster/DSM to exchange dequantized K/V between two CTAs。
8. QK matrix multiply。
9. Softmax / online softmax。
10. PV matrix multiply。
11. Write output/LSE。

FP8 KV cache 每 token 656 bytes：

- 512 bytes FP8 values；
- 16 bytes FP32 scales；
- 128 bytes BF16 RoPE。

文档指出 H800 上该路径可能 dequantization-bound，因为 dequantization cycles 可能超过 MMA cycles。这个判断需要通过 H800 NCU counters 和 microbenchmark 验证。

## Sparse Prefill 计算流程

来源 `.agents/library/operators/FlashMLA/README.md`, `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_prefill.py`, `.agents/library/operators/FlashMLA/tests/lib.py`。

1. Load Q `[s_q,h_q,d_qk]`。
2. Load KV `[s_kv,h_kv,d_qk]`。
3. Load sparse `indices` `[s_q,h_kv,topk]`。
4. Gather selected KV tokens。
5. QK compute。
6. max/logsumexp/softmax。
7. PV compute。
8. Output write and optional `max_logits`/`lse` write。

Sparse prefill 的 `s_q` 可远大于 decoding，测试中含 `s_q=4096` 的性能 cases。功耗建模需要区分 decoding 的 small `s_q` 与 prefill 的 large `s_q`。

## 原子行为拆解

| 阶段 | 主要硬件资源 | 可能 NCU metrics | 可能 SASS/PTX 指令 | Bound 类型 | 是否适合 microbenchmark |
| --- | --- | --- | --- | --- | --- |
| Q load | HBM/L2/L1, LSU | global load sectors, L1/L2 hit rate | `LDG`, vector load | memory | 是 |
| KV cache load | HBM/L2/L1, LSU, TMA | dram/lts sectors, bandwidth, TMA if exposed | `LDG`, `LDGSTS`, TMA-lowered SASS | memory | 是 |
| block/page metadata | L2/L1, integer ALU | global load, integer op counts | `LDG`, `IADD3`, `IMAD`, `LOP3` | memory/control | 是 |
| sparse index load | L2/L1, integer ALU | global load, branch/predicate | `LDG`, `ISETP`, `IADD3` | memory/control | 是 |
| FP8 scale load | HBM/L2/L1 | load sectors by width | `LDG` variants | memory | 是 |
| dequantization | CUDA cores, conversion pipe | instruction mix, pipe utilization | `F2F`, `I2F`, `F2I`, `FMUL`, `LOP3` variants, actual SASS TBD | compute/control | 是 |
| QK | Tensor Core | tensor pipe utilization, WGMMA count | `WGMMA`/SASS `HGMMA`, `MMA`, `LDSM` | compute | 是 |
| softmax | CUDA cores, SFU, reductions | SFU, FP32 ALU, shared/register ops | `MUFU`, `FADD`, `FMUL`, `FFMA`, `FSETP`, `SHFL`, shared ops | compute/control | 是 |
| PV | Tensor Core | tensor pipe utilization, WGMMA count | `WGMMA`/`HGMMA`, `MMA`, `LDSM` | compute | 是 |
| output write | LSU, HBM/L2 | global stores, sectors | `STG` | memory | 是 |
| mask/causal | predicate/control | branch, predicate inst | `ISETP`, `PLOP3`, `SEL`, `BRA` | control | 是 |
| reduction | CUDA cores, shared/register | shared ops, warp ops | `SHFL`, `LDS`, `STS`, `RED`, `BAR` | compute/sync | 是 |
| layout transform | shared/register, LSU | shared load/store, integer ops | `LDS`, `STS`, `PRMT`, `MOV` | memory/control | 是 |
| shared staging | shared memory, TMA | shared load/store, async copy | `LDS`, `STS`, `LDSM`, `LDGSTS`, TMA | memory/sync | 是 |
| register accumulation | register file, tensor/CUDA cores | register pressure, occupancy | tensor accumulators, `FFMA`, `MOV` | compute | 间接 |
| DSM/CTA cluster | distributed shared memory | cluster metrics if available, shared ops | `.shared::cluster`, `st.async`, `barrier.cluster`, `mbarrier` | sync/memory | 是 |

## Microbenchmark 设计建议

### Dense Decoding

| 阶段 | Benchmark 目标 | 输入变量 | 推荐扫参 | 记录指标 | 混杂因素 | 隔离成功判断 |
| --- | --- | --- | --- | --- | --- | --- |
| HBM/L2 KV load | 分离 global load/TMA copy 的能耗 | bytes, stride, cache policy | working set 小于/大于 L2；coalesced/streaming | power, `LDG/LDGSTS`, L2 hit, DRAM bytes | TMA lowering 变化、cache warm state | hit/miss 与目标一致，opcode 稳定 |
| WGMMA QK/PV | Tensor Core dynamic energy | dtype, m/n/k shape, stages | BF16/FP16, one SM90 WGMMA shape 起步 | tensor opcode counts, tensor utilization | shared load 和 barrier 占比 | WGMMA/HGMMA 占比高且随 iters 线性 |
| Online softmax | CUDA core + SFU/reduction | row length, dtype | 64/128/256/512 elements | ALU/SFU/SHFL/shared counts | compiler fusion、tensor overlap | 无 tensor 指令，softmax opcode mix 稳定 |
| SplitKV/combine | reduction/output aggregation | num_splits, output size | 1/2/4/8 splits | kernel list, stores, reductions | launch overhead、dependent launch | 单独 kernel 可定位，runtime 可放大 |

### Sparse Decoding

| 阶段 | Benchmark 目标 | 输入变量 | 推荐扫参 | 记录指标 | 混杂因素 | 隔离成功判断 |
| --- | --- | --- | --- | --- | --- | --- |
| sparse index | irregular index load 和 address calc | `topk`, distribution, invalid ratio | topk 512/2048/8192/32768 | global load, branch/predicate, L2 hit | random seed 和 locality | index load 与 address op 随 topk 线性 |
| FP8 KV load | 656-byte token layout load | topk, coalescing, layout | contiguous/random page | bytes, sectors, load width | dequantization 混入 | load-only variant 可控制 |
| dequantization | FP8->BF16 + scale multiply | d_qk 512/576 | 512 FP8 + 4 scale, optional RoPE | conversion/FP ALU counts | actual compiler lowering | conversion/FP op 占比高，tensor 指令少 |
| DSM crossover | cluster shared exchange | cluster size, bytes | cluster=2 baseline | shared/async/barrier counts | cluster launch constraints | `st.async`/barrier opcode 可见 |
| mbarrier/barrier | sync overhead | waits per loop | arrive/wait loops | barrier opcode counts, runtime | deadlock risk | counts 线性，kernel stable |

### Sparse Prefill

| 阶段 | Benchmark 目标 | 输入变量 | 推荐扫参 | 记录指标 | 混杂因素 | 隔离成功判断 |
| --- | --- | --- | --- | --- | --- | --- |
| Q/K gather | sparse gather memory behavior | `s_q`, `topk`, locality | s_q 1/62/213/4096; topk 128/512/2048 | L2/HBM bytes, global load | cache reuse by repeated indices | hit rate 可预测 |
| QK/PV tensor | sparse prefill tensor load | h_q, d_qk, topk | h_q 64/128, d_qk 512/576 | tensor op counts | softmax overlap | tensor count 按 FLOPs 缩放 |
| softmax/reduction | large `s_q` reduction | topk, invalid ratio | topk 128/512/2048/4096 | SFU/ALU/shared | memory stalls | 无 tensor variant 可对照 |

## H800 首批 operator profiling shapes

这些 shapes 来自 FlashMLA README/tests，作为 profiling 起点，不代表最终覆盖。

| 类别 | 初始 shapes |
| --- | --- |
| Dense decoding | `b=128`, `s_q=1/2`, `s_k=4096/8192/16384/32768`, `h_q=128`, `h_kv=1`, `d_qk=576`, `d_v=512`, `block_size=64` |
| Sparse decoding | `b=128`, `s_q=2`, `s_k=32768`, `topk=2048`, `h_q=128`, `h_kv=1`, `d_qk=576`, FP8 KV cache |
| Sparse decoding peak | `topk=16384/32768`, `h_q=64/128`, `d_qk=512/576` |
| Sparse prefill | `s_q=4096`, `s_kv=8192/32768/65536/98304/131072`, `topk=2048`, `h_q=128`, `d_qk=576` |

## 输出到模型的特征

每个 FlashMLA operator run 至少应输出：

- kernel list 和 kernel names；
- per-kernel runtime；
- per-kernel SASS opcode counts；
- per-kernel global/shared/local load/store counts；
- L1/L2/HBM bytes 或 sector metrics；
- tensor instruction counts；
- occupancy、registers per thread、shared memory per CTA；
- operator-level NVML power trace；
- idle/static baseline id；
- shape parameters；
- build commit、CUDA/driver/NCU version。

## 注意事项

- Dense decoding docs 中的 H800 peak bandwidth/TFLOPS 是 FlashMLA 文档报告值，需本机确认。
- Sparse decoding 中 `st.async`、cluster barrier、DSM 的实际 SASS 表达要通过 `cuobjdump`/`nvdisasm` 和 NCU opcode metrics 确认。
- FlashMLA 可能 launch splitkv 和 combine 多个 kernels；operator power validation 必须聚合完整 operator call path。
- Programmatic dependent launch 和 tile scheduler 会影响 overlap，不能把所有阶段能耗简单按 wall-clock power 峰值相加。
