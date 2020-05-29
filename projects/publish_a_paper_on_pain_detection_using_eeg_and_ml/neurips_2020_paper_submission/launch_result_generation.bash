#!/bin/bash
# Simple Bash script to create the directory structure we need for the analysis
# Then to launch each analysis properly with the right dependencies for the scheduler

# Load the configuration
# OUT_DIR, PROJECT_NAME
. ./analysis.config

# Setting variables
NOW=`date +%s%3N`

$OUT_PATH=`$OUT_DIR/$PROJECT_NAME\_$NOW`

# Creating the Directory structure
`mkdir $OUT_PATH`

# Launching the Feature generation
FEATURE_JOB_ID=`sbatch --export=OUT_PATH='$OUT_PATH' task_0_generate_features.sl`

echo "JOB ID for feature is : $FEATURE_JOB_ID"