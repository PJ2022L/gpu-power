# H800 Environment Protocol

本文件定义 H800 上任何建模实验开始前必须采集的环境信息和命令验证。所有失败命令必须记录失败原因，不允许静默跳过。

## Output

默认采集脚本：

```bash
GPU_ID=0 scripts/00_collect_h800_environment.sh
```

输出目录：

```text
experiments/environment/<timestamp>/
  summary.env
  command_status.tsv
  environment_collection.log
  *.txt
```

## Required Fields

必须记录：

- GPU name
- GPU UUID
- driver version
- CUDA version
- persistence mode
- power limit
- SM clock
- memory clock
- temperature
- utilization
- MIG mode
- ECC mode
- running processes
- `nvidia-smi topo -m`
- git commit
- hostname
- container image / container name
- Python executable and version inside Docker

本项目不假设额外环境激活步骤；H800 Docker container 使用默认 `python`。

## Mandatory Command Checks

必须验证：

```bash
nvidia-smi -pm 1
nvidia-smi -q -d POWER,CLOCK,TEMPERATURE,UTILIZATION
nvidia-smi dmon
nvidia-smi --query-gpu=power.draw,clocks.sm,clocks.mem,temperature.gpu,utilization.gpu --format=csv
```

如果权限允许，尝试验证：

```bash
nvidia-smi -lgc <min_clock,max_clock>
nvidia-smi -lmc <min_mem_clock,max_mem_clock>
nvidia-smi -pl <power_limit>
```

脚本使用以下可选环境变量触发锁频/功耗限制验证：

```bash
VERIFY_SM_CLOCK_RANGE=1410,1410
VERIFY_MEM_CLOCK_RANGE=1593,1593
VERIFY_POWER_LIMIT=700
```

实际数值必须由 H800 机器支持的 clock/power range 决定。

## Required Decision

每次实验前，Main Agent 必须根据环境包判断：

- GPU 是否独占。
- clock 是否锁定或至少完整记录。
- power limit 是否固定或至少完整记录。
- temperature 是否在可接受范围。
- 是否存在 MIG/MPS/ECC/topology 影响。
- 工具版本是否与上次实验一致。

环境不合格时，实验只能标记为 exploratory，不能进入 fitting 或 E2E validation。

## Source

- H800 power measurement protocol: `.agents/knowledge/POWER_MEASUREMENT_PROTOCOL.md`
- Route map: `.agents/knowledge/ROUTE_MAP.md`
- Script: `scripts/00_collect_h800_environment.sh`
