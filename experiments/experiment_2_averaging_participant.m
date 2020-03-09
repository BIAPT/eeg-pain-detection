%{
    This script was written by Yacine Mahdid 2019-11-10 for the analysis of
    the Pain EEG data collected from the Shrinner hospital.
    Here we are using no_pain and hot1 values
%}
%% Make a script to iterate over the healthy participants folder
% Setting up path variables
base_dir = "/home/yacine/Documents/pain_and_eeg/results/msk";
%% Setting up experiment variables (this will be shipped inside the helper function)
% The variables are in the calculate_features function

% The participants folder are named HE001 to HE014
% we can generate them like this  sprintf('%03d',participant_id)
num_participant = 65; % we have 12 because after that we have different labeling
participant_label = cell(num_participant,1);
participant_path = cell(num_participant,1);
for p_id = 1:num_participant
    participant_label{p_id} = sprintf('ME%03d',p_id);
    participant_path{p_id} = sprintf('%s/%s',base_dir,participant_label{p_id});
end

%% make an array of channels to remove (these that don't appear for all channels)

% Count all the channels presence
labels = {};
count = [];
for p_id = 1:num_participant

    % Create the path
    data_path = sprintf('%s/%s.mat',base_dir,participant_label{p_id});
    
    % Load the data
    data = load(data_path);
    data = data.result;
    
    channels_location = data.healthy.sp.metadata.channels_location;
    for l_i = 1:length(channels_location)
        curr_channels = channels_location(l_i).labels;
        insert_index = find_label(curr_channels, labels);
        
        % if index is not there we will append to what we already have
        if(insert_index == -1)
           labels{end+1} = curr_channels;
           count(end+1) = 1;
        else
            % if its already there we increment it by one
            count(insert_index) = count(insert_index) + 1;
        end
    end
    
end

% At this point we should have 2 vector that tells us how much of each
% labels appeared in each EEG device.

%% keep only the channels that have a equal to num_participant-1
threshold = num_participant; % we are excluding HE007
good_labels = {};
index = 1;
for i = 1:length(labels)
    if(count(i) == num_participant)
       good_labels{index} = labels{i};
       index = index + 1;
    end
end

% Get the new num of channels
min_channels = length(good_labels);

%% Iterate over all the participant and gather the baseline and pain
result = struct();

% spectrogram
baseline_avg_spectrum = zeros(1,167);
pain_avg_spectrum = zeros(1,167);

% topo
baseline_avg_td = zeros(1,min_channels);
pain_avg_td = zeros(1,min_channels);

% pe
baseline_avg_pe = zeros(1,min_channels);
baseline_avg_norm_pe = zeros(1,min_channels);
pain_avg_pe = zeros(1,min_channels);
pain_avg_norm_pe = zeros(1,min_channels);

% wPLI
baseline_avg_wpli = zeros(min_channels,min_channels);
pain_avg_wpli = zeros(min_channels,min_channels);

% dPLI
baseline_avg_dpli = zeros(min_channels,min_channels);
pain_avg_dpli = zeros(min_channels,min_channels);

% Channels location
reduced_location = [];

for p_id = 1:num_participant
    disp(sprintf("Analyzing participant: %s",participant_label{p_id}));

    % Create the path
    data_path = sprintf('%s/%s.mat',base_dir,participant_label{p_id});
    
    % Load the data
    data = load(data_path);
    data = data.result;
    
    %% Spectrogram
    % Add up the spectrograms (and average them across time)
    baseline_avg_spectrum = baseline_avg_spectrum + mean(data.healthy.sp.data.spectrums,1);
    pain_avg_spectrum = pain_avg_spectrum + mean(data.hot_pain.sp.data.spectrums,1);
    frequencies_spectrum = data.healthy.sp.data.frequencies; % this should be the same at each iteration

    % Get the location file for this participant
    channels_location = data.healthy.sp.metadata.channels_location;
    
    %% Topographic Map
    % Filter the topographic map and average them through time
    baseline_td = data.healthy.td.data.power;
    pain_td = data.hot_pain.td.data.power;
    
    [baseline_td, reduced_location] = filter_vector(baseline_td, channels_location, good_labels);
    [pain_td, ~] = filter_vector(pain_td, channels_location, good_labels);
    
    % Accumulate the values
    baseline_avg_td = baseline_avg_td + baseline_td;
    pain_avg_td = pain_avg_td + pain_td;
    
    %% Permutation Entropy
    % Filter the pe vector and average them through time
    baseline_pe = data.healthy.pe.data.permutation_entropy;
    baseline_norm_pe = data.healthy.pe.data.normalized_permutation_entropy;
    pain_pe = data.hot_pain.pe.data.permutation_entropy;
    pain_norm_pe = data.hot_pain.pe.data.normalized_permutation_entropy;
    
    [baseline_pe,~] = filter_vector(baseline_pe, channels_location, good_labels);
    [baseline_norm_pe,~] = filter_vector(baseline_norm_pe, channels_location, good_labels);
    [pain_pe, ~] = filter_vector(pain_pe, channels_location, good_labels);
    [pain_norm_pe, ~] = filter_vector(pain_norm_pe, channels_location, good_labels);
    
    % Accumulate the values
    baseline_avg_pe = baseline_avg_pe + baseline_pe;
    baseline_avg_norm_pe = baseline_avg_norm_pe + baseline_norm_pe;
    pain_avg_pe = pain_avg_pe + pain_pe;
    pain_avg_norm_pe = pain_avg_norm_pe + pain_norm_pe;
    
    %% Weighted Phase Lag Index
    % Filter the wpli matrix and average through time
    baseline_wpli = data.healthy.wpli.data.avg_wpli;
    pain_wpli = data.hot_pain.wpli.data.avg_wpli;
    
    [baseline_wpli, ~] = filter_matrix(baseline_wpli, channels_location, good_labels);
    [pain_wpli, ~] = filter_matrix(pain_wpli, channels_location, good_labels);
    
    % Accumulate the values
    baseline_avg_wpli = baseline_avg_wpli + baseline_wpli;
    pain_avg_wpli = pain_avg_wpli + pain_wpli;
    
    %% directed Phase Lag Index
    % Filter the dpli matrix and average through time
    baseline_dpli = data.healthy.dpli.data.avg_dpli;
    pain_dpli = data.hot_pain.dpli.data.avg_dpli;
    
    [baseline_dpli, ~] = filter_matrix(baseline_dpli, channels_location, good_labels);
    [pain_dpli, ~] = filter_matrix(pain_dpli, channels_location, good_labels);
    
    % Accumulate the values
    baseline_avg_dpli = baseline_avg_dpli + baseline_dpli;
    pain_avg_dpli = pain_avg_dpli + pain_dpli;
    
end

num_participant = num_participant-1;
% Average the spectrum accumulated
result.baseline_spectrum = baseline_avg_spectrum/num_participant;
result.pain_spectrum = pain_avg_spectrum/num_participant;
result.frequencies_spectrum = frequencies_spectrum;

% Average the topographic map accumulated
result.baseline_td = baseline_avg_td/num_participant;
result.pain_td = pain_avg_td/num_participant;

% Average the permutation entropy accumulated
result.baseline_pe = baseline_avg_pe/num_participant;
result.baseline_norm_pe = baseline_avg_norm_pe/num_participant;
result.pain_pe = pain_avg_pe/num_participant;
result.pain_norm_pe = pain_avg_norm_pe/num_participant;

% Average the weighted phase lag index accumulated
result.baseline_wpli = baseline_avg_wpli/num_participant;
result.pain_wpli = pain_avg_wpli/num_participant;

% Average the directed phase lag index accumulated
result.baseline_dpli = baseline_avg_dpli/num_participant;
result.pain_dpli = pain_avg_dpli/num_participant;

% Add-in the location
result.reduced_location = reduced_location;

% Save these average participant to the output directory
output_path = sprintf('%s/MEAVG.mat',base_dir);
save(output_path, 'result')

% Helper function to find out where the current channels is w/r to the
% labels
function [insert_index] = find_label(curr_channels, labels)
    insert_index = -1;
    for l_i = 1:length(labels)
        % if our label is already there then we return the index
        if(strcmp(curr_channels,labels{l_i}))
            insert_index = l_i;
            break;
        end
    end
end

% Helper function to filter a matrix of data based on labels
function [filt_matrix, filt_location] = filter_matrix(matrix, location, good_labels)
    % get channels to remove
    to_remove = get_to_remove(location, good_labels);
    
    % copying the value
    filt_matrix = matrix;
    filt_location = location;
    
    % removing the rows 
    filt_matrix(to_remove,:) = [];
    % removing the cols
    filt_matrix(:,to_remove) = [];
    
    % removing the location
    filt_location(to_remove) = [];
end

% Helper function to filter a vector of data based on labels
function [filt_vector, filt_location] = filter_vector(vector, location, good_labels)

    % get the channels to remove
    to_remove = get_to_remove(location, good_labels);

    % Copying the value
    filt_vector = vector;
    filt_location = location;
    
    % Remove the channels
    filt_vector(to_remove) = [];
    filt_location(to_remove) = [];
    
end

function [to_remove] = get_to_remove(location,good_labels)
    % Iterating over the vector to find the channels to remove
    to_remove = [];
    for i = 1:length(location)
        if(~is_in_labels(location(i).labels,good_labels))
            to_remove = [to_remove,i];
        end
    end
end

% Helper function to check if label is in good_labels
function [is_exist] = is_in_labels(label,good_labels)
    is_exist = 0;
    for i = 1:length(good_labels)
       if(strcmp(label,good_labels{i}))
          is_exist = 1;
          break;
       end
    end
end