#!/bin/bash -l

# ---- EDIT THIS PATH (must match project_dir used in the rename step) ----
project_dir=/gpfs/Labs/Dovat/HiC_2025_QUO1018022
# ---------------------------------------------------------------------------

# entries are "SubProject/SampleName" — must exactly match the rename step
# All S# numbers below are CONFIRMED against `ls -ltr` output of the actual
# raw fastq files in each sub-project directory.
entries=(
        "JRP10/ND8_HiC_S1"
        "JRP10/AUS50_HiC_S2"
        "JRP10/AUS51_HiC_S3"
        "JRP10/AUS52_HiC_S4"
        "JRP10/AUS60_HiC_S5"

        "JRP9/ND2_HiC_S1"
        "JRP9/ND3_HiC_S2"
        "JRP9/ND4_HiC_S3"
        "JRP9/ND5_HiC_S4"
        "JRP9/ND6_HiC_S5"

        "JRP8/CHLA21_HiChIP_S1"
        "JRP8/SJBALL11_HiChIP_S2"
        "JRP8/CHLA47_HiChIP_S3"
        "JRP8/CHLA24_HiChIP_S4"
        "JRP8/CHLA57_HiChIP_S5"
        "JRP8/CHLA60_HiChIP_S6"
        "JRP8/PAVDRS_HiChIP_S7"
        "JRP8/AUS174_HiC_S8"

        "JRP11/AUS61_HiC_S1"
        "JRP11/AUS63_HiC_S2"
        "JRP11/AUS84_HiC_S3"
        "JRP11/AUS87_HiC_S4"
        "JRP11/AUS95_HiC_S5"

        "YDP10/CHLA51_HiChIP_S1"
        "YDP10/ALL_53_HiChIP_S2"
        "YDP10/PVCRK_HiChIP_S3"
        "YDP10/W13_HiChIP_S4"
        "YDP10/CHLA28_HiChIP_S5"
        "YDP10/LAX7_HiC_S6"
        "YDP10/CHLA_54_HiC_S7"

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

        sub_project_dir="${project_dir}/${subproject}"
        sample_fastq_dir="${sub_project_dir}/FASTQ/${sample}"

        run_hic_dir="${sub_project_dir}/run_hic"
        data_dir="${run_hic_dir}/data"          # holds hg38 genome/index used by -g hg38
        scripts_dir="${run_hic_dir}/scripts"
        sample_run_dir="${scripts_dir}/${sample}"
        job_dir="${sub_project_dir}/JOBS/runHiC_mapping"

        mkdir -p "${data_dir}" "${sample_run_dir}" "${job_dir}"

        job_file="${job_dir}/${sample}_runHiC.sbatch"
        log_file="${job_dir}/${sample}_runHiC.log"

cat <<EOF> "$job_file"
#!/bin/bash -l
#SBATCH --job-name=runHiC_${subproject}_${sample}
#SBATCH --output=${log_file}
#SBATCH --error=${log_file}
#SBATCH --ntasks=1
#SBATCH --time=6-0
#SBATCH --partition=compute
#SBATCH --account=lab_dovat
#SBATCH --cpus-per-task=20

module load runHiC
module load bwa

cd "${sample_run_dir}"

runHiC mapping -p "${data_dir}" -g hg38 -f "${sample_fastq_dir}" -F FASTQ -A bwa-mem -t 20 \
        --include-readid --drop-seq --chunkSize 3000000 --logFile runHiC-mapping.log

runHiC filtering --pairFolder pairs-hg38/ --logFile runHiC-filtering.log --nproc 20

runHiC quality -m datasets.tsv -L filtered-hg38

EOF
        echo "${job_file}"
        echo "${log_file}"

        sbatch "${job_file}"
done
