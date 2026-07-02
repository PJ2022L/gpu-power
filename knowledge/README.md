# GPU Power Knowledge Base

本知识库服务于 `gpu-power` 的核心目标：

> 在 H800 上预测 GEMM、FlashMLA、FlashAttention v2/v3/v4 五类算子的性能与功耗；通过 microbenchmark 测出构建这些算子的 SASS 指令类功耗；最终让算子功耗预测值与实测值误差控制在 10% 以内。

Wattchmen 是主要方法参考：它提供了“从 SASS 指令级别自底向上构建 GPU energy model”的思想。AccelWattch 不是复现目标，只作为公开 microbenchmark、NVML 测功脚本和 profiling 流程的参考。

## 快速索引

| 遇到的问题 | 去哪里看 | 说明 |
| --- | --- | --- |
| Wattchmen 原始论文在哪里？ | `library/PDF/essay/Wattchmen-Watching the Wattchers.pdf` | 原始 PDF，只放原文，不放整理笔记。 |
| Wattchmen 的总结在哪里？ | `00-reference_essay/wattchmen/01-paper-summary.md` | 论文主要思想、贡献、评估结果和限制。 |
| Wattchmen 的建模公式在哪里？ | `00-reference_essay/wattchmen/02-modeling-method.md` | `E_const + E_static + E_dynamic`、线性方程组、非负求解、instruction energy table。 |
| 怎么设计 SASS microbenchmark？ | `00-reference_essay/wattchmen/03-microbenchmark-design.md` | 最重要的复现文档：ALU、control、memory、tensor/WGMMA、TMA/async benchmark 的设计原则。 |
| H800 上怎么测功耗？ | `00-reference_essay/wattchmen/04-measurement-protocol.md` | 定频、独占 GPU、warmup/cooldown、NVML 采样、NCU 分离采样、日志字段。 |
| 实验前 checklist 在哪里？ | `00-reference_essay/reproduction/checklist.md` | 跑实验前检查环境、GPU、clock、power、NCU 指标和日志完整性。 |
| AccelWattch 有什么可借鉴？ | `00-reference_essay/accelwattch/accelwattch-reference.md` | 只借鉴公开 microbenchmark 和 profiler 流程，不采用其 V100 组件级功耗模型。 |
| H800 规格和待确认字段在哪里？ | `01_hardware/h800/h800-hopper-notes.md` | H800 SXM/HGX 相关信息、TODO 规格表、本机采集命令。 |
| Hopper 架构特性在哪里？ | `01_hardware/hopper/README.md` | WGMMA/HGMMA、TMA、thread-block cluster、async barrier 等架构共性入口。 |
| Memory hierarchy 怎么建模？ | `01_hardware/memory_hierarchy/README.md` | L1/L2/HBM、shared memory、cache hit/miss、TMA 路径等跨硬件主题。 |
| Python/PyTorch harness 规范在哪里？ | `02_tools/python_torch/README.md` | Python 调算子、shape/dtype 参数、`conda activate vla`、日志字段。 |
| CUDA C++ benchmark harness 规范在哪里？ | `02_tools/cuda_cpp/README.md` | C++/CUDA 二进制、CLI 参数、checksum、energy/profiler 双模式。 |
| NVCC 编译怎么记录？ | `02_tools/nvcc/README.md` | `-arch/-gencode`、`nvcc --version`、compile command、binary hash。 |
| PTX 相关问题查哪里？ | `02_tools/ptx/README.md` | inline PTX、PTX 到 SASS lowering、PTX 不是最终建模单位。 |
| SASS opcode 怎么分类？ | `02_tools/sass/README.md` | SASS dump、opcode taxonomy、direct/grouped/scaled/bucketed 策略。 |
| NCU/Nsight Compute 指标在哪里？ | `02_tools/ncu_nsight_compute/README.md` | SASS opcode count、memory/cache metrics、`ncu --query-metrics`。 |
| Nsight Systems 用来做什么？ | `02_tools/nsight_systems/README.md` | operator 会启动哪些 kernels、timeline、NVTX、CPU/GPU 对齐。 |
| NVML API 用法在哪里？ | `02_tools/nvml/README.md` | power/energy/clock/temperature/utilization 采样职责。 |
| GEMM 算子资料在哪里？ | `03_operators/gemm/README.md` | GEMM shapes、实现来源、tensor core SASS、10% 功耗验证目标。 |
| FlashMLA 资料在哪里？ | `03_operators/flashmla/README.md` | FlashMLA decode/prefill、KV/cache、memory/SASS 关注点。 |
| FlashAttention v2/v3/v4 分别在哪里？ | `03_operators/flashattention_v2/README.md`, `03_operators/flashattention_v3/README.md`, `03_operators/flashattention_v4/README.md` | 每个版本单独记录实现、shape、kernel、SASS 和功耗验证。 |
| 原始 PDF 和 repo 链接放哪里？ | `library/README.md` | 原始资料库。PDF 放 `library/PDF/...`，代码仓库只在 `library/repo/README.md` 放链接。 |

## 目录职责

| 目录 | 职责 | 不应该放什么 |
| --- | --- | --- |
| `00-reference_essay/` | 论文阅读、方法论总结、复现实验规范 | 不放硬件规格细节，不放算子 shape 选择。 |
| `01_hardware/` | H800/B200/Hopper/Blackwell/Memory hierarchy 硬件知识 | 不放工具命令细节，不放论文长摘要。 |
| `02_tools/` | Python、CUDA、NVCC、PTX、SASS、NCU、Nsight Systems、NVML 工具链说明 | 不放具体算子实验结论，不放原始 PDF。 |
| `03_operators/` | GEMM、FlashMLA、FlashAttention v2/v3/v4 算子级资料 | 不放通用工具教程，不放硬件白皮书原文。 |
| `library/` | 原始资料与链接索引 | 不放整理后的知识总结，不 clone/copy 代码仓库。 |

## 关键路径

```text
knowledge/
  00-reference_essay/
    wattchmen/
      01-paper-summary.md
      02-modeling-method.md
      03-microbenchmark-design.md
      04-measurement-protocol.md
    accelwattch/
      accelwattch-reference.md
    reproduction/
      checklist.md
  01_hardware/
    h800/
      h800-hopper-notes.md
    b200/
    hopper/
    blackwell/
    memory_hierarchy/
  02_tools/
    python_torch/
    cuda_cpp/
    nvcc/
    ptx/
    sass/
    ncu_nsight_compute/
    nsight_systems/
    nvml/
  03_operators/
    gemm/
    flashmla/
    flashattention_v2/
    flashattention_v3/
    flashattention_v4/
  library/
    PDF/
      essay/
      tech_manual/
    repo/
```

## 推荐阅读顺序

如果你是从零开始理解项目：

1. `00-reference_essay/wattchmen/01-paper-summary.md`
2. `00-reference_essay/wattchmen/02-modeling-method.md`
3. `00-reference_essay/wattchmen/03-microbenchmark-design.md`
4. `00-reference_essay/wattchmen/04-measurement-protocol.md`
5. `01_hardware/h800/h800-hopper-notes.md`
6. `02_tools/README.md`
7. `03_operators/README.md`

如果你要准备跑实验：

1. `00-reference_essay/reproduction/checklist.md`
2. `02_tools/python_torch/README.md` 或 `02_tools/cuda_cpp/README.md`
3. `02_tools/nvml/README.md`
4. `02_tools/ncu_nsight_compute/README.md`
5. `02_tools/nsight_systems/README.md`
6. 对应算子目录，例如 `03_operators/gemm/README.md`

如果你要补硬件知识：

1. `01_hardware/h800/h800-hopper-notes.md`
2. `01_hardware/hopper/README.md`
3. `01_hardware/memory_hierarchy/README.md`
4. `library/PDF/tech_manual/README.md`

## 建模边界

本项目的目标模型是：

- operator-driven：最终预测对象是 GEMM、FlashMLA、FlashAttention v2/v3/v4；
- SASS-class based：测量并建模这些算子使用到的 SASS 指令类；
- bottom-up：由 SASS 指令类能耗、memory hierarchy 行为、constant/static energy 汇总到算子能耗；
- H800-grounded：训练数据来自 H800 实测，不直接套用 V100/A100/H100 表；
- validated：以算子实测功耗为 ground truth，目标误差不超过 10%。

## 项目约定

- H800 SXM/HGX 是第一目标；B200/Blackwell 暂作后续扩展。
- Python 脚本运行前执行 `conda activate vla`。
- 实验脚本必须把命令和超参数打印到 log，便于复现。
- 每次测量必须记录 GPU ID、UUID、driver、CUDA、`ncu` 版本、clock、power limit、temperature 和目标命令。
- 绘图脚本放到对应 figure 文件夹。
- 代码仓库资料只在 `library/repo/README.md` 记录链接，不复制、不 clone 到 `knowledge/library/repo/`。

## 当前风险

- Wattchmen 没有开源，实现需要根据论文独立复现。
- H800 公开规格不完整，不能写死未确认的 SM/cache/HBM/NVLink 数值。
- Nsight Compute 指标名随版本变化，写脚本前必须用 `ncu --query-metrics` 确认。
- FlashAttention/FlashMLA 可能使用生成代码、模板实例化或手写汇编路径，必须 profile 实际二进制。
