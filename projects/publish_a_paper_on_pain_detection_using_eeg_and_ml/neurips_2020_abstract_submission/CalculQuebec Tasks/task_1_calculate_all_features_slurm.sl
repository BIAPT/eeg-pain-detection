#!/bin/bash -l
#SBATCH --job-name=matlab_yacine08_job
#SBATCH --account=def-sblain # adjust this to match the accounting group you are using to submit jobs
#SBATCH --time=0-3:00         # adjust this to match the walltime of your job (in hours)
#SBATCH --nodes=1      
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12      # adjust this if you are using parallel commands
#SBATCH --mem=4000            # adjust this according to the memory requirement per node you need (this is MegaByte)
#SBATCH --mail-user=yacine.mahdid@mail.mcgill.ca # adjust this to match your email address
#SBATCH --mail-type=ALL

# Choose a version of MATLAB by loading a module:
export MATLABPATH=/lustre03/project/6010672/yacine08:$MATLABPATH
module load matlab/2018a

# Remove -singleCompThread below if you are using parallel commands:
srun matlab -nodisplay -r "task_1_calculate_all_features"