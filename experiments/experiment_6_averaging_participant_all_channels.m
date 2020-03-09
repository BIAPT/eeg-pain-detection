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

rejected_participant = [34, 42, 46, 50, 52, 53, 56, 59, 65, 48];
% The participants folder are named HE001 to HE014
% we can generate them like this  sprintf('%03d',participant_id)
num_participant = 65; % we have 12 because after that we have different labeling
participant_label = cell(num_participant,1);
participant_path = cell(num_participant,1);
for p_id = 1:num_participant
    participant_label{p_id} = sprintf('ME%03d',p_id);
    participant_path{p_id} = sprintf('%s/%s',base_dir,participant_label{p_id});
end

%% Iterate over all the participant and gather the baseline and pain
result = struct();

% spectrogram
baseline_avg_spectrum = zeros(1,167);
pain_avg_spectrum = zeros(1,167);

% Channels location
m_location = [];
first_participant = 1;
real_num_participant = 0;
for p_id = 1:num_participant
    disp(sprintf("Analyzing participant: %s",participant_label{p_id}));

    % Create the path
    data_path = sprintf('%s/%s.mat',base_dir,participant_label{p_id});
    
    % Load the data
    % We try to load the data from this participant, if its not there we
    % continue
    try
        data = load(data_path);
        data = data.result;
    catch
        continue
    end
    
    % There is a problem with that participant
    if(ismember(p_id,rejected_participant))
        continue
        
    end
    
    %% Spectrogram
    % Add up the spectrograms (and average them across time)
    avg_spectrum_time = squeeze(mean(data.healthy.sp.data.spectrums,1))';
    avg_spectrum_window = mean(avg_spectrum_time,1);
    baseline_avg_spectrum = baseline_avg_spectrum + avg_spectrum_window;
    
    avg_spectrum_time = squeeze(mean(data.hot_pain.sp.data.spectrums,1))';
    avg_spectrum_window = mean(avg_spectrum_time,1);
    pain_avg_spectrum = pain_avg_spectrum + avg_spectrum_window;
    frequencies_spectrum = data.healthy.sp.data.frequencies; % this should be the same at each iteration

    % Get the location file for this participant
    channels_location = data.healthy.sp.metadata.channels_location;
    % We se the merged location to be the first participant channel
    % location
    if(first_participant == 1)
        m_location = channels_location;
        num_channel = length(m_location);
        first_participant = 0; % turn the switch off
        
        % topo
        baseline_avg_td = zeros(1, num_channel);
        pain_avg_td = zeros(1,num_channel);

        % pe
        baseline_avg_pe = zeros(1,num_channel);
        baseline_avg_norm_pe = zeros(1,num_channel);
        pain_avg_pe = zeros(1,num_channel);
        pain_avg_norm_pe = zeros(1,num_channel);

        % wPLI
        baseline_avg_wpli = zeros(num_channel,num_channel);
        pain_avg_wpli = zeros(num_channel,num_channel);

        % dPLI
        baseline_avg_dpli = zeros(num_channel, num_channel);
        pain_avg_dpli = zeros(num_channel, num_channel);
    end
    
    temp_location = m_location;
    
    %% Topographic Map
    % Filter the topographic map and average them through time
    baseline_td = data.healthy.td.data.power;
    pain_td = data.hot_pain.td.data.power;
    
    % Here is the only part we overwrite the m_location
    [baseline_avg_td, m_location] = merge_vector(baseline_avg_td, temp_location, baseline_td, channels_location);
    [pain_avg_td, ~] = merge_vector(pain_avg_td, temp_location, pain_td, channels_location);
   
    %% Permutation Entropy
    % Filter the pe vector and average them through time
    baseline_pe = data.healthy.pe.data.permutation_entropy;
    baseline_norm_pe = data.healthy.pe.data.normalized_permutation_entropy;
    pain_pe = data.hot_pain.pe.data.permutation_entropy;
    pain_norm_pe = data.hot_pain.pe.data.normalized_permutation_entropy;
    
    [baseline_avg_pe, ~] = merge_vector(baseline_avg_pe, temp_location, baseline_pe, channels_location);
    [baseline_avg_norm_pe, ~] = merge_vector(baseline_avg_norm_pe, temp_location, baseline_norm_pe, channels_location);
    [pain_avg_pe, ~] = merge_vector(pain_avg_pe, temp_location, pain_pe, channels_location);
    [pain_avg_norm_pe, ~] = merge_vector(pain_avg_norm_pe, temp_location, pain_norm_pe, channels_location);
    
    
    %% Weighted Phase Lag Index
    % Filter the wpli matrix and average through time
    baseline_wpli = data.healthy.wpli.data.avg_wpli;
    pain_wpli = data.hot_pain.wpli.data.avg_wpli;
   
    if(isnan(pain_wpli) | isnan(baseline_wpli))
        disp("ISNAN")
        continue 
    end
    
    [baseline_avg_wpli, ~] = merge_matrix(baseline_avg_wpli, temp_location, baseline_wpli, channels_location);
    [pain_avg_wpli, ~] = merge_matrix(pain_avg_wpli, temp_location, pain_wpli, channels_location);
    
    %% directed Phase Lag Index
    % Filter the dpli matrix and average through time
    baseline_dpli = data.healthy.dpli.data.avg_dpli;
    pain_dpli = data.hot_pain.dpli.data.avg_dpli;
    
    [baseline_avg_dpli, ~] = merge_matrix(baseline_avg_dpli, temp_location, baseline_dpli, channels_location);
    [pain_avg_dpli, ~] = merge_matrix(pain_avg_dpli, temp_location, pain_dpli, channels_location);
    
    real_num_participant = real_num_participant + 1;
end

% Average the spectrum accumulated
result.baseline_spectrum = baseline_avg_spectrum/real_num_participant;
result.pain_spectrum = pain_avg_spectrum/real_num_participant;
result.frequencies_spectrum = frequencies_spectrum;

% Average the topographic map accumulated
result.baseline_td = baseline_avg_td;
result.pain_td = pain_avg_td;

% Average the permutation entropy accumulated
result.baseline_pe = baseline_avg_pe;
result.baseline_norm_pe = baseline_avg_norm_pe;
result.pain_pe = pain_avg_pe;
result.pain_norm_pe = pain_avg_norm_pe;

% Average the weighted phase lag index accumulated
result.baseline_wpli = baseline_avg_wpli;
result.pain_wpli = pain_avg_wpli;

% Average the directed phase lag index accumulated
result.baseline_dpli = baseline_avg_dpli;
result.pain_dpli = pain_avg_dpli;

% Add-in the location
result.m_location = m_location;

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


% Merge two matrix together
function [m_matrix, m_location] = merge_matrix(matrix_1, location_1, matrix_2, location_2)
    % Merge the two location together
    m_location = merge_location(location_1, location_2);
    m_labels = get_labels(m_location);
    
    m_matrix = zeros(length(m_location),length(m_location));
    
    % Add in the matrix 1 at the right spot
    for i = 1:length(matrix_1)
        label_i = location_1(i).labels;
        for j = 1:length(matrix_1)
            label_j = location_1(j).labels;
            
            insert_i = find_label(label_i, m_labels);
            insert_j = find_label(label_j, m_labels);
            
            m_matrix(insert_i,insert_j) = matrix_1(i,j);          
       end
    end
    
    for i = 1:length(matrix_2)
        label_i = location_2(i).labels;
        for j = 1:length(matrix_2)
            label_j = location_2(j).labels;
            
            insert_i = find_label(label_i, m_labels);
            insert_j = find_label(label_j, m_labels);
            
            
            current_value = m_matrix(insert_i, insert_j);
            % we just put it there if equal to 0
            if(current_value == 0)
              m_matrix(insert_i, insert_j) = matrix_2(i,j);
            % we divide by two if not equal to 0   
            else
               m_matrix(insert_i, insert_j) = (current_value + matrix_2(i,j)) / 2;
            end            
        end
    end
end

% Merge two vector together
function [m_vector,m_location] = merge_vector(vector_1, location_1, vector_2, location_2)
    % Merge the two location together
    m_location = merge_location(location_1, location_2);
    m_labels = get_labels(m_location);
    
    m_vector = zeros(1,length(m_location));
    % Add in the vector 1 at the right spot
    for i = 1:length(vector_1)
        label = location_1(i).labels;
        insert_index = find_label(label, m_labels);
        m_vector(insert_index) = vector_1(i);
    end
    
    % Add in the vector 2 at the right spot and divide by 2 if needed
    for i = 1:length(vector_2)
       label = location_2(i).labels;
       insert_index = find_label(label, m_labels);
       
       % we just put it there if equal to 0
       if(m_vector(insert_index) == 0)
          m_vector(insert_index) = vector_2(i);
       % we divide by two if not equal to 0   
       else
           m_vector(insert_index) = (m_vector(insert_index) + vector_2(i)) / 2;
       end
    end
end

function [labels] = get_labels(location)
    labels = {};
    for i = 1:length(location)
       labels{i} = location(i).labels; 
    end
end

function [m_location] = merge_location(location_1, location_2)
   m_location = location_1;
   
   for i = 1:length(location_2)
       label = location_2(i).labels;
       % If the label is not present we append the whole thing to the
       % m_location
       if(is_label_present(label,location_1) == 0)
           m_location(end+1) = location_2(i);
       end
       
   end
end

% Function to check if a label is present in a given location
function [is_present] = is_label_present(label,location)
    is_present = 0;
    for i = 1:length(location)
       if(strcmp(label,location(i).labels))
          is_present = 1;
          return
       end
    end
end