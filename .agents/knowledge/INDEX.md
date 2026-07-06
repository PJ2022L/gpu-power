# H800 Power Knowledge Index

本知识库面向 H800 系列 GPU 上的算子功耗测量、拆解和建模。目标是支持后续从 `micro-benchmark -> SASS energy table -> GEMM/FlashMLA/FlashAttention v3 operator power prediction` 的实验迭代，而不是在当前机器运行实验。

## 项目目标

在 H800/Hopper/SM90 环境中复现 Wattchmen 的方法论：用可控 microbenchmark 训练 SASS 指令级动态能耗表，结合 idle/static baseline、runtime、SASS opcode counts、cache/memory behavior，预测 GEMM、FlashMLA、FlashAttention v3 的 operator-level power/energy。首轮工程目标误差约为 15% 以内。

## 核心问题路由

| 遇到的问题 | 先读 | 继续读 |
| --- | --- | --- |
| 原始资料在哪里，哪些需要精读？ | [SOURCE_INVENTORY.md](SOURCE_INVENTORY.md) | 对应 `.agents/library/...` 原文 |
| Wattchmen 到底怎么建模？ | [PAPER_NOTES.md](PAPER_NOTES.md) | [POWER_MODELING_METHODS.md](POWER_MODELING_METHODS.md), [POWER_MODEL_PLAN.md](POWER_MODEL_PLAN.md) |
| AccelWattch 能借鉴什么，不能借鉴什么？ | [POWER_MODELING_METHODS.md](POWER_MODELING_METHODS.md) | [MICROBENCHMARK_CATALOG.md](MICROBENCHMARK_CATALOG.md) |
| 如何区分 constant/static/dynamic power？ | [POWER_MODELING_METHODS.md](POWER_MODELING_METHODS.md) | [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md), [POWER_MODEL_PLAN.md](POWER_MODEL_PLAN.md) |
| H800 上怎样测 idle、active baseline、operator power？ | [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md) | [H800_PLATFORM_CONTEXT.md](H800_PLATFORM_CONTEXT.md) |
| repeated runs 的方差多大才算有效？ | [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md) | 后续实验 `QUALITY.md` |
| 如何设计 SASS 级 microbenchmark？ | [MICROBENCHMARK_CATALOG.md](MICROBENCHMARK_CATALOG.md) | [POWER_MODEL_PLAN.md](POWER_MODEL_PLAN.md) |
| global/shared/L2/HBM benchmark 如何隔离？ | [MICROBENCHMARK_CATALOG.md](MICROBENCHMARK_CATALOG.md) | [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md) |
| Hopper WGMMA/TMA/mbarrier 该怎么进入模型？ | [H800_PLATFORM_CONTEXT.md](H800_PLATFORM_CONTEXT.md) | [FLASHMLA_POWER_DECOMPOSITION.md](FLASHMLA_POWER_DECOMPOSITION.md), [MICROBENCHMARK_CATALOG.md](MICROBENCHMARK_CATALOG.md) |
| FlashMLA 可以拆成哪些功耗阶段？ | [FLASHMLA_POWER_DECOMPOSITION.md](FLASHMLA_POWER_DECOMPOSITION.md) | [EXPERIMENT_VARIABLES.md](EXPERIMENT_VARIABLES.md) |
| Dense Decoding、Sparse Decoding、Sparse Prefill 的参数怎么扫？ | [EXPERIMENT_VARIABLES.md](EXPERIMENT_VARIABLES.md) | [FLASHMLA_POWER_DECOMPOSITION.md](FLASHMLA_POWER_DECOMPOSITION.md) |
| Nsight Compute / Nsight Systems / NVML / nvidia-smi 分别做什么？ | [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md) | [H800_PLATFORM_CONTEXT.md](H800_PLATFORM_CONTEXT.md) |
| 如何从 microbenchmark 重建整体算子功耗？ | [POWER_MODEL_PLAN.md](POWER_MODEL_PLAN.md) | [POWER_MODELING_METHODS.md](POWER_MODELING_METHODS.md) |
| 新旧路径怎么查，避免旧路径失效？ | [ROUTE_MAP.md](ROUTE_MAP.md) | [SOURCE_INVENTORY.md](SOURCE_INVENTORY.md) |
| MSAE 和 dynamic/energy/latency error 怎么定义？ | [METRICS.md](METRICS.md) | [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md) |
| H800 环境包需要采什么？ | [H800_ENVIRONMENT_PROTOCOL.md](H800_ENVIRONMENT_PROTOCOL.md) | [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md) |
| static + constant baseline 怎么建模？ | [STATIC_POWER_MODEL.md](STATIC_POWER_MODEL.md) | [POWER_MODEL_PLAN.md](POWER_MODEL_PLAN.md) |
| 动态 SASS 模型如何迭代？ | [DYNAMIC_POWER_MODEL.md](DYNAMIC_POWER_MODEL.md) | [SASS_CATEGORY_MAP.md](SASS_CATEGORY_MAP.md) |
| SASS category 和动态计数怎么定义？ | [SASS_CATEGORY_MAP.md](SASS_CATEGORY_MAP.md) | [MICROBENCHMARK_CATALOG.md](MICROBENCHMARK_CATALOG.md) |
| E2E validation 报告怎么写？ | [E2E_EVALUATION_REPORT.md](E2E_EVALUATION_REPORT.md) | [METRICS.md](METRICS.md) |
| 如果误差大于 15%，下一步怎么判断？ | [NEXT_ITERATION_PLAN.md](NEXT_ITERATION_PLAN.md) | [POWER_MODEL_PLAN.md](POWER_MODEL_PLAN.md), [MICROBENCHMARK_CATALOG.md](MICROBENCHMARK_CATALOG.md), 后续 `harness/exec-plans/xx-plan.md` |

## Knowledge 模块导航

| 文档 | 职责 |
| --- | --- |
| [SOURCE_INVENTORY.md](SOURCE_INVENTORY.md) | `.agents/library` 的资料清单、分类、优先级和精读状态。 |
| [PAPER_NOTES.md](PAPER_NOTES.md) | 逐篇论文/笔记提炼功耗建模知识，Wattchmen 为主线，AccelWattch 为参考。 |
| [POWER_MODELING_METHODS.md](POWER_MODELING_METHODS.md) | 按方法比较 SASS 指令级、组件级、counter-driven、black-box、white-box 建模。 |
| [FLASHMLA_POWER_DECOMPOSITION.md](FLASHMLA_POWER_DECOMPOSITION.md) | FlashMLA dense/sparse decoding 和 sparse prefill 的功耗阶段拆解与 microbenchmark 建议。 |
| [MICROBENCHMARK_CATALOG.md](MICROBENCHMARK_CATALOG.md) | 开源 ubenchmark/FlashMLA benchmark catalog，判断哪些代码可改造成 H800 功耗 benchmark。 |
| [POWER_MEASUREMENT_PROTOCOL.md](POWER_MEASUREMENT_PROTOCOL.md) | H800 测功规范：隔离、锁频、NVML、NCU/Nsys、重复性阈值、日志字段。 |
| [EXPERIMENT_VARIABLES.md](EXPERIMENT_VARIABLES.md) | FlashMLA、GEMM、microbenchmark 和功耗环境扫参变量体系。 |
| [POWER_MODEL_PLAN.md](POWER_MODEL_PLAN.md) | 从 MVP 到 operator prediction 的建模路线、公式、overlap 处理和验证标准。 |
| [H800_PLATFORM_CONTEXT.md](H800_PLATFORM_CONTEXT.md) | H800/Hopper 平台上下文、可迁移架构信息、需本机确认字段和采集命令。 |
| [ROUTE_MAP.md](ROUTE_MAP.md) | 当前 `.agents/library`、`.agents/knowledge`、`harness`、`experiments` 的 canonical 路由。 |
| [METRICS.md](METRICS.md) | MSAE、dynamic power error、energy error、latency error 和非负功耗约束。 |
| [H800_ENVIRONMENT_PROTOCOL.md](H800_ENVIRONMENT_PROTOCOL.md) | H800 实验前环境采集字段、命令和通过/失败判定。 |
| [STATIC_POWER_MODEL.md](STATIC_POWER_MODEL.md) | static + constant active power baseline 的建模计划和产物格式。 |
| [DYNAMIC_POWER_MODEL.md](DYNAMIC_POWER_MODEL.md) | 动态 SASS 功耗模型、迭代闭环、fitting requirements。 |
| [SASS_CATEGORY_MAP.md](SASS_CATEGORY_MAP.md) | H800 SASS category 初版映射和动态计数要求。 |
| [E2E_EVALUATION_REPORT.md](E2E_EVALUATION_REPORT.md) | GEMM/FlashMLA/FA3 E2E validation 报告模板。 |
| [NEXT_ITERATION_PLAN.md](NEXT_ITERATION_PLAN.md) | MSAE 超标后的 error review 和下一轮计划模板。 |

## H800-only 边界

- 实验目标：H800 SXM/HGX 容器环境，架构按 Hopper/SM90 处理。
- H100 白皮书只作为 Hopper 架构机制参考；H100 数值不能直接代替 H800。
- B200/Blackwell 资料本轮不进入建模计划。
- FlashMLA README/docs 中报告的 H800 性能数字可以作为“项目来源声明”，但仍需本机确认。

## 主要来源

- Wattchmen: `.agents/library/papers/Wattchmen-Watching the Wattchers.pdf`
- Wattchmen 旧笔记: `.agents/library/papers/wattchmen/*.md`
- AccelWattch: `.agents/library/papers/2021-MICRO-AccelWattch-Kandiah.pdf`
- FlashMLA: `.agents/library/operators/FlashMLA/`
- Microbenchmarks: `.agents/library/benchmarks/gpuwattch-ubench/`, `.agents/library/benchmarks/accelwattch-ubench/`
- NVIDIA docs: `.agents/library/docs/nvidia-h100-tensor-core-hopper-whitepaper.pdf`, `.agents/library/docs/ptx_isa_9.0.pdf`, `.agents/library/docs/nsight-compute.pdf`, `.agents/library/docs/nsight-systems.pdf`, `.agents/library/docs/CUDA_Binary_Utilities.pdf`

## Canonical Knowledge Rule

`.agents/knowledge/` 是唯一知识库目录。不要再创建或引用 root-level `knowledge/`。原始资料只放在 `.agents/library/`；实验输出只放在 `experiments/`。
