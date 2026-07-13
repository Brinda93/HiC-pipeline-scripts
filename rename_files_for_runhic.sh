#!/bin/bash -l
#SBATCH --job-name=Rename_QUO1018022
#SBATCH --output=rename_QUO1018022.%j.txt
#SBATCH --error=rename_QUO1018022.%j.err
#SBATCH -p compute
#SBATCH -c 1
#SBATCH --mem-per-cpu=4
#SBATCH -A lab_dovat

# ---- EDIT THESE TWO PATHS ----
raw_project_dir=/mnt/labs/DovatLab_RW/raw_data/2025/Yali_HiC/QUO1018022
project_dir=/mnt/labs/DovatLab_RW/raw_data/2025/Yali_HiC/QUO1018022/results     # <- pick/confirm your gpfs working dir
# -------------------------------

# entries are "SubProject/SampleName" — SampleName includes the _S# suffix.
# All S# numbers below are CONFIRMED against `ls -ltr` output of the actual
# raw fastq files in each sub-project directory.

entries=(
        # JRP10
        "JRP10/ND8_HiC_S1"
        "JRP10/AUS50_HiC_S2"
        "JRP10/AUS51_HiC_S3"
        "JRP10/AUS52_HiC_S4"
        "JRP10/AUS60_HiC_S5"

        # JRP9
        "JRP9/ND2_HiC_S1"
        "JRP9/ND3_HiC_S2"
        "JRP9/ND4_HiC_S3"
        "JRP9/ND5_HiC_S4"
        "JRP9/ND6_HiC_S5"

        # JRP8
        "JRP8/CHLA21_HiChIP_S1"
        "JRP8/SJBALL11_HiChIP_S2"
        "JRP8/CHLA47_HiChIP_S3"
        "JRP8/CHLA24_HiChIP_S4"
        "JRP8/CHLA57_HiChIP_S5"
        "JRP8/CHLA60_HiChIP_S6"
        "JRP8/PAVDRS_HiChIP_S7"
        "JRP8/AUS174_HiC_S8"

        # JRP11
        "JRP11/AUS61_HiC_S1"
        "JRP11/AUS63_HiC_S2"
        "JRP11/AUS84_HiC_S3"
        "JRP11/AUS87_HiC_S4"
        "JRP11/AUS95_HiC_S5"

        # YDP10
        "YDP10/CHLA51_HiChIP_S1"
        "YDP10/ALL_53_HiChIP_S2"
        "YDP10/PVCRK_HiChIP_S3"
        "YDP10/W13_HiChIP_S4"
        "YDP10/CHLA28_HiChIP_S5"
        "YDP10/LAX7_HiC_S6"
        "YDP10/CHLA_54_HiC_S7"

        # YDP11
        "YDP11/CHLA_54_HiChIP_S1"
        "YDP11/W0_HiChIP_S2"
        "YDP11/LAX7_HiChIP_S3"
        "YDP11/ALL_58_HiChIP_S4"
        "YDP11/PAVYCL_HiChIP_S5"
        "YDP11/PAVVIE_HiChIP_S6"
        "YDP11/ALL_57_HiChIP_S7"
        "YDP11/PAWFUU_HiChIP_S8"
        "YDP11/K09_HiChIP_S9"
        "YDP11/ALL_59_HiChIP_S10"

        # YDP12
        "YDP12/ALL_7_HiChIP_S1"
        "YDP12/ALL_82_HiChIP_S2"
        "YDP12/ALL_25_HiChIP_S3"
        "YDP12/U937_wt_HiChIP_S4"
        "YDP12/U937_CX_HiChIP_S5"
        "YDP12/Nalm6_wt_HiChIP_S6"
        "YDP12/Nalm6_KO_IK_K8_HiChIP_S7"
        "YDP12/CHLA11_HiChIP_S8"
        "YDP12/CHLA23_HiChIP_S9"
        "YDP12/CHLA25_HiChIP_S10"
)

for entry in "${entries[@]}"; do
        subproject="${entry%%/*}"
        sample="${entry##*/}"

        raw_sample_dir="${raw_project_dir}/${subproject}"
        fastq_working_dir="${project_dir}/${subproject}/FASTQ/${sample}"
        mkdir -p "${fastq_working_dir}"

        for r in 1 2; do
                src="${raw_sample_dir}/${sample}_R${r}_001.fastq.gz"
                dst="${fastq_working_dir}/${sample}_${r}.fastq.gz"

                if [ -f "${src}" ]; then
                        # symlink to avoid duplicating multi-hundred-GB files;
                        # switch to `cp` if you need an independent copy
                        ln -s "${src}" "${dst}"
                        echo "Linked: ${dst}"
                else
                        echo "WARNING: missing ${src}  (check S# for ${subproject}/${sample})"
                fi
        done
done

