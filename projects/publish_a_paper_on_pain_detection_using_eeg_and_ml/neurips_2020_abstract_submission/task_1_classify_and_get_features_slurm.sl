#!/bin/bash
#SBATCH --job-name=ml_yacine08_job
#SBATCH --account=def-sblain
#SBATCH --mem-per-cpu=90000      # increase as needed
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mail-user=yacine.mahdid@mail.mcgill.ca # adjust this to match your email address
#SBATCH --mail-type=ALL

module load python/3.7.4
module load scipy-stack

virtualenv --no-download $SLURM_TMPDIR/env
source $SLURM_TMPDIR/env/bin/activate
pip install --no-index --upgrade pip
pip install -U scikit-learn
python task_1_classify_and_get_features.py