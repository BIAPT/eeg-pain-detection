#!/bin/bash -l
# Simple Bash script to create the directory structure we need for the analysis
# Then to launch each analysis properly with the right dependencies for the scheduler

# Load the configuration
# OUT_DIR, PROJECT_NAME
. ./analysis.config

# Setting variables
NOW=`date +%s%3N`

OUT_PATH="$OUT_DIR/$PROJECT_NAME-$NOW"

# Creating the Directory structure
mkdir "$OUT_PATH"
