# Pain Recognition with EEG
In this project, we are analyzing 24 channels dry EEG data coming from the Shrinner Hospital in two patient population: Healthy and participant with MSK.

## Analysis Flow
In this folder there are at the time of writing about 6 experiments. The one that matters are the experiment 5,6 and 3,4 in that order. Merging these experiments into two would be a great idea and is set as a new issue. Here is how to run the experiment:
0) Make sure you have the cleaned data sitting in your computer.


1) Run experiment_5_gathering_all_participant: Which will calculate all the features for all the participant and store it in a result folder. Right now the data is still incomplete and a bit messy for some participant, so there will be some refactoring to do.
2) Run experiment_6_averaging_participant_all_channels: Which will run through each of the participants result and create an average participant result for each of the metric studied. This will create a (M | H)EAVG.mat which will be used for the plotting.
3) Run experiment_3_plotting_participants: To make all the plots except the wPLI/dPLI plot. Save these figures for latter.
4) Finally run experiment_4_reordering_matrix: Which will take the unordered wPLI/dPLI matrix and will input an order of frontal to posterior `{'Fp1','Fp2','F3','Fz','F4','F7','F8','C3','Cz','C4','T3','T4','T5','T6','P3','Pz','P4','O1','O2'}`.

## Methods
Here is the general methods that we used in order to generate the figures and the results. Before starting the analysis the EEG data was cleaned by our collaborators at the Shrinner Hospital. Artifact were removed, the  data was filtered and bad channels were removed. This processing pipeline assume then that the data is cleaned and that it contains the following files: ('no_pain.set' or 'rest.set') and 'hot1.set'.

Here we used the baseline data which is either named as 'no_pain.set' or 'rest.set' and the hot pain data. The baseline data can have two names since we added a control condition for the movement of the participant after a few data points were collected. This control condition is currently **not used for analysis**, but it should be used to assess how much the hand movement accounts for the EEG response we are seeing.

The feature calculation pipeline for both the baseline and the pain condition is as follow and the code can be found ine experiment_5 in the function calculate_features():

### Power Spectra 
Parameters are the following: 
- bandpass = 1Hz to 50Hz
- window length = full length of the recording
- step size = 0.1 seconds
- number of tapers = 3
- spectrum window size = 3
- time bandwidth product = 2

### Topographic Distribution of Power
Parameters are the following:
- bandpass = 8Hz to 13Hz
- window size = full length of the recording

### Permutation Entropy
Parameters are the following:
- bandpass = 8Hz to 13Hz
- window size = full length of the recording
- embedding dimension = 5
- time lag = 4

### Weighted Phase Lag Index and Directed Phase Lag Index
Parameters are the following:
- bandpass = 8Hz to 13Hz
- window size = full length of the recording
- number surrogates = 10
- p value = 0.05

### Figure Generation and Comparison Between Conditions
To compare between condition we generate three figures: The first one is the analysis technique result at baseline, the second is the result during the hot pain stimulation and the last one is the log ratio of the baseline over pain; Which looks like this Log(Baseline ./ Pain). If there is one value per channel we divide the elements elementwise.
