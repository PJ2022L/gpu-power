# Knowledge Route Map

本文件是当前仓库的路径路由表。知识库已统一到 `.agents/knowledge/`，后续 agent 必须以本表的 canonical path 为准。若路径不存在，先搜索相近目录并更新本表，不要直接使用旧路径。

## 当前结论

| 项 | Canonical path | 状态 |
| --- | --- | --- |
| 原始资料入口 | `.agents/library/` | 存在 |
| H800 知识库 | `.agents/knowledge/` | 存在，唯一 canonical knowledge |
| 根 knowledge 目录 | `knowledge/` | 已删除，不再使用 |
| 旧论文目录 | `knowledge/00-reference_essay/` | 不存在，已迁移 |
| 旧 library 目录 | `knowledge/library/` | 不存在，已迁移 |

## 旧路径到新路径

| 旧路径 | 新路径 / 替代路径 | 文件类型 | 资料用途 | 是否存在 | 后续 canonical path |
| --- | --- | --- | --- | --- | --- |
| `knowledge/library/PDF/essay/Wattchmen-Watching the Wattchers.pdf` | `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf` | paper PDF | Wattchmen 主论文，SASS 指令级能耗建模主来源 | 旧路径否；新路径是 | `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf` |
| `knowledge/library/PDF/essay/2021-MICRO-AccelWattch-Kandiah.pdf` | `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf` | paper PDF | AccelWattch 组件级模型和 microbenchmark/测量参考 | 旧路径否；新路径是 | `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf` |
| `knowledge/00-reference_essay/wattchmen/` | `.agents/library/papers/wattchmen/` and `.agents/knowledge/PAPER_NOTES.md` | notes | Wattchmen 摘要、建模、microbenchmark、测量协议 | 旧路径否；新路径是 | `.agents/knowledge/PAPER_NOTES.md`, `.agents/knowledge/POWER_MODELING_METHODS.md`, `.agents/knowledge/MICROBENCHMARK_CATALOG.md` |
| `knowledge/00-reference_essay/accelwattch/` | `.agents/library/papers/accelwattch-reference/` and `.agents/knowledge/POWER_MODELING_METHODS.md` | notes | AccelWattch 参考边界 | 旧路径否；新路径是 | `.agents/knowledge/POWER_MODELING_METHODS.md` |
| `knowledge/library/repo/gpu-app-collection/src/cuda/accelwattch-ubench` | `.agents/library/benchmarks/accelwattch-ubench/` | benchmark repo copy/link | AccelWattch CUDA microbenchmark | 旧路径否；新路径是 | `.agents/library/benchmarks/accelwattch-ubench/` |
| `knowledge/library/repo/gpu-app-collection/src/cuda/gpuwattch-ubench` | `.agents/library/benchmarks/gpuwattch-ubench/` | benchmark repo copy/link | GPUWattch CUDA microbenchmark | 旧路径否；新路径是 | `.agents/library/benchmarks/gpuwattch-ubench/` |
| `knowledge/01_hardware/h800/` | `.agents/knowledge/H800_PLATFORM_CONTEXT.md` | knowledge | H800/Hopper 平台上下文 | 旧路径否；新路径是 | `.agents/knowledge/H800_PLATFORM_CONTEXT.md` |
| `knowledge/02_tools/nvml/` | `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`, `src/power/nvml_sampler.py` | knowledge/tool source | NVML 测功规范和采样脚本 | 旧路径否；替代路径是 | `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`, `src/power/nvml_sampler.py` |
| `knowledge/02_tools/ncu_nsight_compute/` | `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`, `.agents/library/docs/nsight-compute.pdf` | docs/knowledge | NCU SASS/cache metrics | 旧路径否；替代路径是 | `.agents/library/docs/nsight-compute.pdf` |
| `knowledge/02_tools/nsight_systems/` | `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`, `.agents/library/docs/nsight-systems.pdf` | docs/knowledge | Nsys timeline/operator kernel list | 旧路径否；替代路径是 | `.agents/library/docs/nsight-systems.pdf` |
| `knowledge/02_tools/ptx/` | `.agents/library/docs/ptx_isa_9.0.pdf`, `.agents/knowledge/H800_PLATFORM_CONTEXT.md` | official docs | PTX/WGMMA/mbarrier/TMA/cluster 参考 | 旧路径否；新路径是 | `.agents/library/docs/ptx_isa_9.0.pdf` |
| `knowledge/02_tools/sass/` | `.agents/library/docs/CUDA_Binary_Utilities.pdf`, `.agents/knowledge/MICROBENCHMARK_CATALOG.md` | official docs/knowledge | cuobjdump/nvdisasm/SASS 验证 | 旧路径否；新路径是 | `.agents/library/docs/CUDA_Binary_Utilities.pdf` |
| `knowledge/03_operators/flashmla/` | `.agents/library/operators/FlashMLA/`, `.agents/knowledge/FLASHMLA_POWER_DECOMPOSITION.md` | operator repo/knowledge | FlashMLA 源码、docs、benchmark、拆解 | 旧路径否；新路径是 | `.agents/library/operators/FlashMLA/` |
| `knowledge/03_operators/gemm/` | 待接入真实 GEMM/CUTLASS/cuBLASLt benchmark source | operator source | GEMM 来源未接入；不要使用空占位目录 | 旧路径否；新路径否 | `.agents/library/operators/<gemm-source>/` after import |
| `knowledge/03_operators/flashattention_v3/` | 待接入真实 FlashAttention v3 source | operator source | FlashAttention v3 来源未接入；不要使用空占位目录 | 旧路径否；新路径否 | `.agents/library/operators/<flashattention-v3-source>/` after import |
| `knowledge/README.md` / `knowledge/INDEX.md` | `.agents/knowledge/INDEX.md` | route/index | 知识库入口 | 旧路径否；新路径是 | `.agents/knowledge/INDEX.md` |

## 当前存在的关键目录

| 路径 | 文件类型 | 资料用途 | Canonical |
| --- | --- | --- | --- |
| `.agents/library/papers/` | papers/notes | Wattchmen、AccelWattch、论文笔记 | 是 |
| `.agents/library/docs/` | official_docs | Hopper whitepaper、PTX ISA、Nsight、CUDA binary utilities | 是 |
| `.agents/library/benchmarks/accelwattch-ubench/` | benchmarks | CUDA instruction/memory/static/tensor microbenchmarks | 是 |
| `.agents/library/benchmarks/gpuwattch-ubench/` | benchmarks | 早期 GPUWattch microbenchmark | 是 |
| `.agents/library/operators/FlashMLA/` | operators | FlashMLA 源码、docs、tests、benchmark | 是 |
| `.agents/library/operators/Gemm/` | operators | 空占位目录已删除；真实 source 接入后再创建 | 否 |
| `.agents/library/operators/flashattention_v3/` | operators | 空占位目录已删除；真实 source 接入后再创建 | 否 |
| `.agents/library/experiments/` | experiments | 当前不保留空目录；如未来迁入原始实验记录再创建 | 否 |
| `experiments/` | experiments | 本工程后续实验输出目录 | 是 |
| `src/power/nvml_sampler.py` | tools | NVML 采样脚本 | 是 |

## 搜索记录

本轮已扫描：

- `library/`: 不存在。
- `.agents/library/`: 存在，是 raw/canonical library；不保留空的 `notes/` 或 `experiments/` 占位目录。
- `.agents/knowledge/`: 存在，是唯一 H800 knowledge base。
- 包含 `accelwattch`, `wattchmen`, `power`, `nvml`, `dcgm`, `flashmla`, `flash-attention`, `flashattention`, `gemm` 的路径。

## 后续维护规则

- 新增 raw paper/repo/manual 时放入 `.agents/library/<category>/` 并更新 `.agents/knowledge/SOURCE_INVENTORY.md`。
- 新增总结性知识时放入 `.agents/knowledge/`，不要重建 root-level `knowledge/`。
- 新增真实实验数据时放入 `experiments/<exp_id>/`，不要放回 `.agents/library/`。
- 如果后续 H100/B200 进入目标范围，新增 platform-specific route，不覆盖 H800 canonical path。
