# Pain Recognition with EEG
In this project, we are analyzing 24 channels dry EEG data coming from the Shrinner Hospital in two patient population: Healthy and participant with MSK.

## Table of Content
- [Code Structure](#code-structure)

## Code Structure
- .doc: where we keep some important documents that the analysis is based on
- milestones: where we keep the different iteration of the codebase, in synch with Github milestones
    - .data: contains data we need for the analysis that are static
    - 0_first_cross_validated_ml_model: its the very first iteration of the machine learning pipeline we did to validate that there was something to do with the data
    - 1_neurips_2020_abstract_submission: This was the modification we brought in for the neurips 2020 asbtract submission. We made the analysis a bit more robust.
    - 2_neurips_2020_paper_submission: A week after the abstract submission for neurips we made some more modification to improve the analysis some more.
    - 3_first_draft_paper: Because of the neurips sumission we had a good start for a paper, we gained some ideas of what to change to make a full papper out of our analysis.
- utils is where utility function (like plotting or reordering) are stored

