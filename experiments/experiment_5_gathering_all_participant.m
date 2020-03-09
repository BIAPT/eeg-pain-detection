%{
    This script was written by Yacine Mahdid 2019-11-10 for the analysis of
    the Pain EEG data collected from the Shrinner hospital.
    Here we are using no_pain and hot1 values
%}
%% Make a script to iterate over the healthy participants folder
% Setting up path variables
base_dir = "/home/yacine/Documents/pain_and_eeg/Cleaned_MSK_EEG/sorted_by_patients";
output_dir = "/home/yacine/Documents/pain_and_eeg/results/msk";
%% Setting up experiment variables (this will be shipped inside the helper function)
% The variables are in the calculate_features function

% The participants folder are named HE001 to HE014
% we can generate them like this  sprintf('%03d',participant_id)
num_participant = 65;
rejected_participant = [34, 42, 46, 50, 52, 53, 56, 59, 65, 48];

participant_label = cell(num_participant,1);
participant_path = cell(num_participant,1);
for p_id = 1:num_participant
    participant_label{p_id} = sprintf('ME%03d',p_id);
    participant_path{p_id} = sprintf('%s/%s',base_dir,participant_label{p_id});
end

%% Iterate over all the participant and gather the baseline and pain
for p_id = 1:num_participant
    disp(sprintf("Analyzing participant: %s",participant_label{p_id}));
    % Create the path
    baseline_name = sprintf('%s_nopain.set',participant_label{p_id});
    hot_pain_name = sprintf('%s_hot1.set',participant_label{p_id});
    
    % Load the data
    % Here will skip those that are messed up
    if(ismember(p_id,rejected_participant))
       continue 
    end
    
    
    % This is to accomodate the new way of labelling the data
    try
        baseline_recording = load_set(baseline_name, participant_path{p_id});
    catch
        disp(sprintf("Participant: %s does not have a nopain.set",participant_label{p_id}))
        baseline_name = sprintf('%s_rest.set',participant_label{p_id});
        baseline_recording = load_set(baseline_name, participant_path{p_id});
    end
    
    % If there is a problem here it means that there is a datapoint missing
    try
        hot_pain_recording = load_set(hot_pain_name, participant_path{p_id});
    catch
        disp(sprintf("Skiping that participant since missing the hot1"));
        continue
    end
    
    % Calculate some features
    result = struct();
    result.healthy = calculate_features(baseline_recording);
    result.hot_pain = calculate_features(hot_pain_recording);
    
    % Save these feature to the output directory
    output_path = sprintf('%s/%s.mat',output_dir,participant_label{p_id});
    save(output_path, 'result')
end

function [result] = calculate_features(recording)
    % Setting the output structure
    result = struct();


    % Setup the global variable for the study
    % window size will be equal to the full length of data
    alpha_band = [8 13]; % alpha will be used for most of the analysis
    full_band = [1 50];
    
    % Spectrogram
    window_size = floor(recording.length_recording / recording.sampling_rate);
    time_bandwith_product = 2;
    number_tapers = 3;
    spectrum_window_size = 3; % in seconds
    step_size = 0.1; % in seconds
    result.sp = na_spectral_power(recording, window_size, time_bandwith_product, number_tapers, spectrum_window_size,full_band, step_size);

    % Topographic Map
    window_size = floor(recording.length_recording / recording.sampling_rate);
    step_size = window_size; % in seconds
    result.td = na_topographic_distribution(recording, window_size, step_size, alpha_band);

    % Permutation Entropy
    window_size = floor(recording.length_recording / recording.sampling_rate);
    step_size = window_size;
    embedding_dimension = 5;
    time_lag = 4;
    result.pe = na_permutation_entropy(recording, alpha_band, window_size , step_size, embedding_dimension, time_lag);

    % wPLI & dPLI
    window_size = 10;
    number_surrogate = 20; % Number of surrogate wPLI to create
    p_value = 0.05; % the p value to make our test on
    step_size = window_size;
    result.wpli = na_wpli(recording, alpha_band, window_size, step_size, number_surrogate, p_value);
    result.dpli = na_dpli(recording, alpha_band, window_size, step_size, number_surrogate, p_value);
end

