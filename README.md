# Privacy-Preserving Distributed Optimal Consensus of High-Order NoMAS

This repository contains MATLAB implementations for distributed optimal consensus experiments on high-order multi-agent systems, including privacy-preserving variants based on Paillier encryption.

The codebase is organized to reproduce the main experiment groups corresponding to Fig. 2, Fig. 3, and Fig. 4 referenced in the original project notes.

## Repository Structure

- `consensus/`
  Baseline distributed optimal consensus implementation used for the experiment corresponding to Fig. 2.

- `consensus_algorithm1/`
  Privacy-preserving consensus implementation with encryption, designed for the direct state difference setting and corresponding to the experiment in Fig. 3.

- `consensus_algorithm2/`
  Privacy-preserving consensus implementation with encryption, designed for the weighted state difference setting and corresponding to the experiment in Fig. 4.

- `comparsion/`
  Supplementary comparison scripts, figures, and data files used to contrast different methods and node settings. The folder name follows the original project spelling.

## Requirements

- MATLAB
- No external toolbox requirements were documented in the original notes

The privacy-preserving implementations include local copies of `PaillierCrypto.m` inside the corresponding experiment folders.

## Quick Reproduction

Clone the repository:

```bash
git clone https://github.com/houshuang18022/Privacy-Preserving-Distributed-Optimal-Consensus-of-High-Order-NoMAS.git
cd Privacy-Preserving-Distributed-Optimal-Consensus-of-High-Order-NoMAS
```

Reproduce the baseline result for Fig. 2:

```matlab
cd consensus
consensus
```

Reproduce the privacy-preserving direct state difference result for Fig. 3:

```matlab
cd consensus_algorithm1
consensus_algorithm1
```

Reproduce the privacy-preserving weighted state difference result for Fig. 4:

```matlab
cd consensus_algorithm2
consensus_algorithm2
```

## Notes

- The repository keeps the original experiment folder names and supporting files.
- The `comparsion/` directory contains intermediate scripts, figures, and `.mat` data generated or used during method comparison.
- If you plan to publish results from this repository, review the scripts and parameter settings in each MATLAB file before rerunning the experiments.
