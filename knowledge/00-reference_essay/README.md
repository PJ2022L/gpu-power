# Reference Essays

This directory stores papers, reading notes, and reproduction methodology that support the H800 operator power project.

## Contents

- `wattchmen/`: primary method reference for SASS-level bottom-up energy modeling.
- `accelwattch/`: public reference for microbenchmarks and NVML profiling infrastructure.
- `reproduction/`: practical checklist and experiment hygiene rules.

## Project Use

Use this directory to answer:

- How should per-SASS-class energy be measured?
- How should microbenchmark energy be converted into an instruction energy table?
- How should operator-level energy be predicted and validated?
- What measurement controls are required to keep power error within 10%?

Do not use this directory for hardware-specific facts or operator-specific profiling notes; those belong in `01_hardware/` and `03_operators/`.
