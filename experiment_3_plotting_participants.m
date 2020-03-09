%{
    This script was written by Yacine Mahdid 2019-11-10 for the analysis of
    the Pain EEG data collected from the Shrinner hospital.
    Here we are using no_pain and hot1 values
%}
%% Make a script to plot the healthy participants folder
% Setting up path variables
result_path = "";

type = 'MSK Average Participants';

data = load(strcat(result_path,'MEAVG.mat'));
data = data.result;

%% Making the Spectrogram plot
%make_spectrogram(data,type);

%% Making the topographic map plot
%make_topographic_map(data,type);

%% Making the permutation entropy map plot
% normalized
%make_norm_permutation_entropy(data,type);

%% Making the wPLI
%make_wpli(data,type);

%% Making the dPLI
%make_dpli(data,type);
