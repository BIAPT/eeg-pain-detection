#!/bin/bash -l
#SBATCH --job-name=matlab_yacine08_job
#SBATCH --account=def-sblain # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=0-6:00         # adjust this to match the walltime of your job (in hours)
#SBATCH --nodes=1      
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40      # adjust this if you are using parallel commands
#SBATCH --mem=90000         # adjust this according to the memory requirement per node you need (this is MegaByte)
#SBATCH --mail-user=yacine.mahdid@mail.mcgill.ca # adjust this to match your email address
#SBATCH --mail-type=ALL

# Choose a version of MATLAB by loading a module:
module load matlab/2018a

# Create temporary job info location
mkdir -p /scratch/$USER/$SLURM_JOB_ID

# Remove -singleCompThread below if you are using parallel commands:
srun matlab -nodisplay -r "task_1_calculate_all_features"

# Cleanup
rm -rf /scratch/$USER/$SLURM_JOB_ID