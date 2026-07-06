# Source Inventory

本文件记录 `.agents/library/` 中可用于 H800 功耗建模项目的资料映射。原始资料不在本轮移动；若目录结构混杂，只在这里记录用途和优先级。

## 分类规则

| 类型 | 判断标准 |
| --- | --- |
| `papers/` | 论文、会议论文、技术报告、已有论文笔记。 |
| `operators/` | FlashMLA、FlashAttention、GEMM 等算子实现、接口、测试和 benchmark。 |
| `benchmarks/` | CUDA micro-benchmark、功耗 benchmark、instruction/cache/tensor benchmark。 |
| `docs/` | NVIDIA 官方架构、CUDA、PTX/SASS、Nsight、工具手册。 |
| `notes/` | 人工整理的读书笔记、复现笔记、项目内部说明。 |
| `experiments/` | 已有实验数据、log、profile、report。当前 library 中未发现稳定实验数据入口。 |

## 高优先级来源

| 路径 | 类型 | 主题 | 与 H800 功耗项目的关系 | 优先级 | 是否需进一步精读 |
| --- | --- | --- | --- | --- | --- |
| `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf` | `papers/` | Wattchmen SASS 指令级能耗建模 | 本项目主要方法来源：microbenchmark、SASS opcode counts、cache hit rates、线性方程组、const/static/dynamic 分解、NVML 稳态测量。 | High | 是 |
| `.agents/library/papers/wattchmen/01-paper-summary.md` | `notes/` | Wattchmen 摘要 | 旧知识库整理，可辅助定位；路径引用已过时，不能直接复制。 | High | 是 |
| `.agents/library/papers/wattchmen/02-modeling-method.md` | `notes/` | Wattchmen 建模方法 | 可复用公式和 solver 约束；需要改写成 H800-only。 | High | 是 |
| `.agents/library/papers/wattchmen/03-microbenchmark-design.md` | `notes/` | SASS 级 microbenchmark 设计 | 可复用 microbenchmark 架构、opcode 验证、memory/tensor 设计；需要更新路径和 H800 限定。 | High | 是 |
| `.agents/library/papers/wattchmen/04-measurement-protocol.md` | `notes/` | 测功协议 | 可复用 NVML、锁频、重复性检查；需要移除旧路径和环境假设。 | High | 是 |
| `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf` | `papers/` | AccelWattch 组件级功耗模型 | 参考公开 microbenchmark、NVML 测量流程、static/constant/dynamic 思想；不是最终 H800 建模目标。 | High | 是 |
| `.agents/library/papers/accelwattch-reference/accelwattch-reference.md` | `notes/` | AccelWattch 参考笔记 | 帮助区分 AccelWattch 与 Wattchmen 的边界。 | Medium | 是 |
| `.agents/library/operators/FlashMLA/README.md` | `operators/` | FlashMLA 总览、接口、H800 性能声明 | H800 目标算子之一，给出 dense decoding、sparse decoding、sparse prefill 支持矩阵和参数。 | High | 是 |
| `.agents/library/operators/FlashMLA/docs/20250422-new-kernel-deep-dive.md` | `operators/` | Dense MLA decoding kernel deep dive | 拆解 dense decoding 的 QK、online softmax、PV、TMA pipelining、WGMMA/Tensor Core 路径。 | High | 是 |
| `.agents/library/operators/FlashMLA/docs/20250929-hopper-fp8-sparse-deep-dive.md` | `operators/` | Hopper FP8 sparse decoding | 拆解 FP8 KV cache、dequantization、DSM/CTA cluster、st.async、barrier 相关功耗来源。 | High | 是 |
| `.agents/library/operators/FlashMLA/benchmark/bench_flash_mla.py` | `operators/` | FlashMLA benchmark 入口 | 可作为 operator profiling/power ground truth 的入口参考；需由 H800 agent 适配日志和 NVML。 | High | 是 |
| `.agents/library/operators/FlashMLA/tests/test_flash_mla_dense_decoding.py` | `operators/` | Dense decoding 测试和性能 shapes | 提供 b、s_q、s_k、h_q、h_kv、causal、varlen 等扫参线索。 | High | 是 |
| `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_decoding.py` | `operators/` | Sparse decoding 测试和性能 shapes | 提供 FP8 sparse decoding 的生产和 peak shapes。 | High | 是 |
| `.agents/library/operators/FlashMLA/tests/test_flash_mla_sparse_prefill.py` | `operators/` | Sparse prefill 测试和性能 shapes | 提供 sparse prefill 的 s_q、s_kv、topk、h_q、d_qk 扫参线索。 | High | 是 |
| `.agents/library/operators/FlashMLA/tests/lib.py` | `operators/` | FlashMLA 测试参数和 testcase 构造 | 统一 TestParam、RawTestParamForDecode、KVScope、FP8 quant/dequant、indices 生成。 | High | 是 |
| `.agents/library/operators/FlashMLA/csrc/api/dense_decode.h` | `operators/` | Dense decode C++ API 约束 | 记录 SM90a、dtype、page block、head dim、splitkv/combine kernel 约束。 | High | 是 |
| `.agents/library/operators/FlashMLA/csrc/api/sparse_decode.h` | `operators/` | Sparse decode C++ API 约束 | 记录 h_q、d_qk、h_kv、topk、SM90/SM100 分支等约束。 | High | 是 |
| `.agents/library/operators/FlashMLA/csrc/api/sparse_fwd.h` | `operators/` | Sparse prefill C++ API 约束 | 用于定位 sparse prefill kernel、参数和 SASS 目标。 | Medium | 是 |

## Benchmark 和 Microbenchmark 来源

| 路径 | 类型 | 主题 | 与 H800 功耗项目的关系 | 优先级 | 是否需进一步精读 |
| --- | --- | --- | --- | --- | --- |
| `.agents/library/benchmarks/gpuwattch-ubench/` | `benchmarks/` | GPUWattch 早期 microbenchmark 套件 | 参考 functional/branching/memory/DRAM/mix/active_cores 结构；代码较旧，需要重写到 H800/CUDA 12 环境。 | High | 是 |
| `.agents/library/benchmarks/gpuwattch-ubench/functional_benchmarks/` | `benchmarks/` | FP/INT/SFU 指令 benchmark | 参考 loop unroll、sink、防优化、指令比例设计。 | High | 是 |
| `.agents/library/benchmarks/gpuwattch-ubench/branching_benchmarks/` | `benchmarks/` | 分支和 lane 活跃度 benchmark | 参考 active lanes/divergence 设计，但 H800 首版只做 uniform branch。 | Medium | 是 |
| `.agents/library/benchmarks/gpuwattch-ubench/memories_benchmarks/` | `benchmarks/` | L1/L2/DRAM/shared/constant/texture benchmark | 参考 pointer chasing、working set、cache hit/miss 控制。 | High | 是 |
| `.agents/library/benchmarks/gpuwattch-ubench/dram_benchmarks/` | `benchmarks/` | DRAM read/write benchmark | HBM/DRAM streaming benchmark 设计参考。 | High | 是 |
| `.agents/library/benchmarks/gpuwattch-ubench/active_cores/` | `benchmarks/` | active SM/core sweep | 参考 static power 与 active SM 数量关系。 | Medium | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/` | `benchmarks/` | AccelWattch microbenchmark 套件 | 更接近现代 CUDA；包含 functional、memory、mix、static_power_modeling、tensor。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/functional_benchmarks/BE_SP_FP_ADD/BE_SP_FP_ADD.cu` | `benchmarks/` | FP32 add benchmark | 参考运行时 iterations、CUDA event timing、unroll 100、固定 grid/block。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/functional_benchmarks/MOV/` | `benchmarks/` | MOV benchmark | 对 H800 SASS energy table 的基础 opcode 有参考价值。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/functional_benchmarks/REG_FILE/` | `benchmarks/` | register file pressure | 参考寄存器读写压力，但需重新定义为 SASS opcode/occupancy 目标。 | Medium | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/memories_benchmarks/BE_L1D_HIT/BE_L1D_HIT.cu` | `benchmarks/` | L1 hit benchmark | 使用 inline PTX `ld.global.ca` 和 pointer chasing，适合改造成 H800 L1-hit 功耗 benchmark。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/memories_benchmarks/BE_L2D_HIT/` | `benchmarks/` | L2 hit benchmark | 参考 L1 miss/L2 hit 控制，H800 需用 NCU metrics 验证。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/memories_benchmarks/BE_MEM_DRAM_Acss/` | `benchmarks/` | DRAM/HBM access benchmark | H800 HBM benchmark 起点。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/static_power_modeling/` | `benchmarks/` | active/static power benchmark | 参考 active-no-op、active cores/lanes、mixed static benchmark。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/static_power_modeling/LIGHT_SM/LIGHT_SM.cu` | `benchmarks/` | low-switching active SM | 可改造成 H800 active-no-op baseline。 | High | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/tensor_benchmarks/TENSOR/tensorcore.cu` | `benchmarks/` | WMMA tensor benchmark | 旧 WMMA 参考；H800 需要升级为 SM90 WGMMA/HGMMA 目标。 | High | 是 |

## NVIDIA 文档来源

| 路径 | 类型 | 主题 | 与 H800 功耗项目的关系 | 优先级 | 是否需进一步精读 |
| --- | --- | --- | --- | --- | --- |
| `.agents/library/docs/nvidia-h100-tensor-core-hopper-whitepaper.pdf` | `docs/` | Hopper/H100 架构白皮书 | H800 属 Hopper 系列，本轮只迁移架构机制：SM、Tensor Core、TMA、thread-block cluster、DSM、HBM/L2、NVLink。H100 数值不能直接当 H800 数值。 | High | 是 |
| `.agents/library/docs/ptx_isa_9.0.pdf` | `docs/` | PTX ISA 9.0 | H800 microbenchmark 的 PTX 诱导、WGMMA、mbarrier、st.async、cluster、tensormap 参考。 | High | 是 |
| `.agents/library/docs/CUDA_Binary_Utilities.pdf` | `docs/` | cuobjdump/nvdisasm 等 binary tools | SASS dump、opcode 验证、binary inspection 必备。 | High | 是 |
| `.agents/library/docs/nsight-compute.pdf` | `docs/` | Nsight Compute | SASS opcode counters、cache metrics、kernel profiling、CSV/export。 | High | 是 |
| `.agents/library/docs/nsight-systems.pdf` | `docs/` | Nsight Systems | CUDA timeline、kernel launch 聚合、NVTX、SQLite/export。 | Medium | 是 |
| `.agents/library/docs/ProfilingGuide.pdf` | `docs/` | CUDA profiling guide | 作为 Nsight/CUPTI 相关背景。 | Medium | 是 |

## 当前未发现或待补来源

| 缺口 | 影响 | 建议 |
| --- | --- | --- |
| H800 官方完整规格文档 | SM 数、HBM 容量/带宽、L2、NVLink 等不能只用 H100/B200 推断。 | 在 H800 机器上用 `nvidia-smi -q`, CUDA deviceQuery, NCU system info 采集并存档。 |
| FlashAttention v3 源码/benchmark | 目标算子之一的 SASS top-k 和 operator power 需要正式来源。 | 后续把 FA3 repo 链接到 `.agents/library/operators/`。 |
| GEMM/CUTLASS benchmark 入口 | GEMM 是首轮 validation operator，需要可复现 runner。 | 使用 FlashMLA vendored CUTLASS 或单独链接 CUTLASS/cublasLt benchmark。 |
| DCGM/NVML 官方 PDF | POWER_MEASUREMENT_PROTOCOL 已给工具边界，但 library 当前没有 NVML/DCGM 原始手册。 | 后续补入 `.agents/library/docs/`，再更新协议。 |
| 已有 H800 实验 log/profile | 当前知识库只构建方法，不含实测结果。 | H800 agent 运行后放到实验目录，不放回 library。 |

## Canonical Knowledge Documents

| 路径 | 用途 |
| --- | --- |
| `.agents/knowledge/INDEX.md` | H800 知识库入口 |
| `.agents/knowledge/SOURCE_INVENTORY.md` | `.agents/library` 资料清单、分类、优先级和精读状态 |
| `.agents/knowledge/ROUTE_MAP.md` | canonical 路由表 |
| `.agents/knowledge/PAPER_NOTES.md` | 论文逐篇笔记 |
| `.agents/knowledge/POWER_MODELING_METHODS.md` | 建模方法比较 |
| `.agents/knowledge/MICROBENCHMARK_CATALOG.md` | microbenchmark catalog |
| `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md` | H800 测功协议 |
| `.agents/knowledge/FLASHMLA_POWER_DECOMPOSITION.md` | FlashMLA 功耗拆解 |
| `.agents/knowledge/EXPERIMENT_VARIABLES.md` | 实验变量体系 |
| `.agents/knowledge/POWER_MODEL_PLAN.md` | 建模路线 |
| `.agents/knowledge/H800_PLATFORM_CONTEXT.md` | H800 平台上下文 |
| `.agents/knowledge/METRICS.md` | MSAE 与 error metric 定义 |
| `.agents/knowledge/H800_ENVIRONMENT_PROTOCOL.md` | H800 环境采集协议 |
| `.agents/knowledge/STATIC_POWER_MODEL.md` | static + constant baseline 建模计划 |
| `.agents/knowledge/DYNAMIC_POWER_MODEL.md` | 动态 SASS 功耗模型迭代计划 |
| `.agents/knowledge/SASS_CATEGORY_MAP.md` | SASS category 与动态计数规则 |
| `.agents/knowledge/E2E_EVALUATION_REPORT.md` | E2E validation 报告模板 |
| `.agents/knowledge/NEXT_ITERATION_PLAN.md` | MSAE 超标后的下一轮计划模板 |

## 来源边界

- 本轮实验目标只写 H800/Hopper/SM90；H100 文档仅作为 Hopper 架构机制参考。
- B200/Blackwell 信息不进入本轮建模计划，除非用于说明“非目标背景”。
- 所有无法确认的 H800 规格、clock、功耗上限、L2/HBM 数值必须标记为“需本机确认”。
