#!/bin/bash
# Simple Bash script to create the directory structure we need for the analysis
# Then to launch each analysis properly with the right dependencies for the scheduler

# Setting variables
OUT_DIR=$1
PROJECT_NAME=$2
NOW=`date +%s%3N`

# Creating the Directory structure
`mkdir $OUT_DIR/$PROJECT_NAME\_$NOW`

# Launching the Feature generation
FEATURE_JOB_ID=`sbatch task_0_generate_features.sl`

echo "JOB ID for feature is : $FEATURE_JOB_ID"