# HiC-pipeline-scripts


Scripts for preparing raw Hi-C / HiChIP fastq data from SeqCenter runs and
running them through [runHiC](https://github.com/XiaoTaoWang/HiC_pipeline)
(mapping → filtering → quality) on the Dovat Lab HPC cluster.

## Background

Raw sequencing data is delivered to a read-only-ish share at:

```
/mnt/labs/DovatLab_RW/raw_data/2025/Yali_HiC/QUO1018022/
```

This project (`QUO1018022`) contains 7 sub-projects (`JRP8`, `JRP9`, `JRP10`,
`JRP11`, `YDP10`, `YDP11`, `YDP12`), each with its own `SampleSheet_*.csv` and
a folder of raw fastq files named like:

```
<SAMPLE>_S<N>_R1_001.fastq.gz
<SAMPLE>_S<N>_R2_001.fastq.gz
```

**Important cluster quirk:** `/mnt/labs/DovatLab_RW/...` is only mounted on
the **login node** — it is not visible from compute nodes, and it does not
support `chmod` (so tools like `git clone` will fail if run from inside it).
All working directories, `git` clones, and Slurm job outputs must live under
`/gpfs/Labs/Dovat/...` instead.

## Scripts

### `rename_files_for_runhic.sh`

Run **directly on the login node with `bash`** — do **not** submit this with
`sbatch`, since compute nodes cannot see `raw_project_dir`.

For each of the 47 samples across all 7 sub-projects, this script:
- creates `${project_dir}/<SubProject>/FASTQ/<sample>/`
- symlinks the raw `_R1_001.fastq.gz` / `_R2_001.fastq.gz` files into that
  folder, renamed to `<sample>_1.fastq.gz` / `<sample>_2.fastq.gz` (the
  naming runHiC expects)

Edit the two path variables at the top before running:

```bash
raw_project_dir=/mnt/labs/DovatLab_RW/raw_data/2025/Yali_HiC/QUO1018022
project_dir=/gpfs/Labs/Dovat/HiC_2025_QUO1018022
```

Usage:

```bash
cd /mnt/labs/DovatLab_RW/raw_data/2025/Yali_HiC/QUO1018022
bash rename_files_for_runhic.sh
```

Check the output for any `WARNING: missing ...` lines — these indicate a
sample/`S#` mismatch and should be resolved before continuing.

### `run_runhic.sh`

Submits one Slurm job per sample (across all 7 sub-projects) that runs:

```
runHiC mapping   -> runHiC filtering   -> runHiC quality
```

Each job requests 20 CPUs and up to 6 days of walltime. Must be run **after**
`rename_files_for_runhic.sh` has completed successfully, and only reads/writes
under `/gpfs/Labs/Dovat/...`, so it can be submitted normally with `sbatch`
from either the login node or run directly as a shell script (it calls
`sbatch` internally per sample):

```bash
bash run_runhic.sh
```

Edit `project_dir` at the top to match what you used in the rename step.
Also confirm the hg38 genome/index referenced by `-g hg38` exists under
`${project_dir}/<SubProject>/run_hic/data/` before submitting — `runHiC`
will fail per-sample otherwise.

## Sample manifest

`S#` suffixes for every sample were confirmed against the actual raw fastq
filenames in each sub-project directory (not just inferred from the sample
sheets). See the `entries=(...)` array at the top of each script for the
full `SubProject/SampleName` list.

| Sub-project | Samples |
|---|---|
| JRP10 | ND8_HiC_S1, AUS50_HiC_S2, AUS51_HiC_S3, AUS52_HiC_S4, AUS60_HiC_S5 |
| JRP9  | ND2_HiC_S1, ND3_HiC_S2, ND4_HiC_S3, ND5_HiC_S4, ND6_HiC_S5 |
| JRP8  | CHLA21_HiChIP_S1, SJBALL11_HiChIP_S2, CHLA47_HiChIP_S3, CHLA24_HiChIP_S4, CHLA57_HiChIP_S5, CHLA60_HiChIP_S6, PAVDRS_HiChIP_S7, AUS174_HiC_S8 |
| JRP11 | AUS61_HiC_S1, AUS63_HiC_S2, AUS84_HiC_S3, AUS87_HiC_S4, AUS95_HiC_S5 |
| YDP10 | CHLA51_HiChIP_S1, ALL_53_HiChIP_S2, PVCRK_HiChIP_S3, W13_HiChIP_S4, CHLA28_HiChIP_S5, LAX7_HiC_S6, CHLA_54_HiC_S7 |
| YDP11 | CHLA_54_HiChIP_S1, W0_HiChIP_S2, LAX7_HiChIP_S3, ALL_58_HiChIP_S4, PAVYCL_HiChIP_S5, PAVVIE_HiChIP_S6, ALL_57_HiChIP_S7, PAWFUU_HiChIP_S8, K09_HiChIP_S9, ALL_59_HiChIP_S10 |
| YDP12 | ALL_7_HiChIP_S1, ALL_82_HiChIP_S2, ALL_25_HiChIP_S3, U937_wt_HiChIP_S4, U937_CX_HiChIP_S5, Nalm6_wt_HiChIP_S6, Nalm6_KO_IK_K8_HiChIP_S7, CHLA11_HiChIP_S8, CHLA23_HiChIP_S9, CHLA25_HiChIP_S10 |

## Directory layout produced

```
${project_dir}/
└── <SubProject>/
    ├── FASTQ/
    │   └── <sample>/
    │       ├── <sample>_1.fastq.gz -> symlink to raw R1
    │       └── <sample>_2.fastq.gz -> symlink to raw R2
    ├── run_hic/
    │   ├── data/           # hg38 genome/index (populate manually)
    │   └── scripts/
    │       └── <sample>/   # runHiC working dir, pairs-hg38/, filtered-hg38/, etc.
    └── JOBS/
        └── runHiC_mapping/
            ├── <sample>_runHiC.sbatch
            └── <sample>_runHiC.log
```
