# Pain Recognition with EEG
In this project, we are analyzing 24 channels dry EEG data coming from the Shrinner Hospital in two patient population: Healthy and participant with MSK.

Code written by Yacine Mahdid in 2020 from home during the Covid-19 pandemic.



## Table of Content
- [Labels](#labels)
- [Code Structure](#code-structure)

## Labels
- rest: is when the participant didn't move while we recorded the data. This was not a very good control since in the hot1/hot2 condition they are moving a cursor
- nopain: is the same thing if a participant has it we need to change it to rest
- covas: is when we told the participant to move the small cursor (this is the better control)
- hot1: the first painful thermal condition
- cold: the only cold bath condition
- hot2: the second painful thermal condition after the cold bath

## Code Structure
- .doc: where we keep some important documents that the analysis is based on
- milestones: where we keep the different iteration of the codebase, in synch with Github milestones
    - .data: contains data we need for the analysis that are static
    - 0_first_cross_validated_ml_model: its the very first iteration of the machine learning pipeline we did to validate that there was something to do with the data
    - 1_neurips_2020_abstract_submission: This was the modification we brought in for the neurips 2020 asbtract submission. We made the analysis a bit more robust.
    - 2_neurips_2020_paper_submission: A week after the abstract submission for neurips we made some more modification to improve the analysis some more.
    - 3_first_draft_paper: Because of the neurips sumission we had a good start for a paper, we gained some ideas of what to change to make a full papper out of our analysis.
- utils is where utility function (like plotting or reordering) are stored

**If you want to reproduce the latest result you need to use the latest milestone**

Starting at milestone 3 we decided to use a JSON file for holding the configuration since at that time we were using MATLAB and Python for the analysis and there was state shared between the two.