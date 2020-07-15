%% Yacine Mahdid July 10
% This generator will calculate the following feature:
% - power
% - wpli
% - peak frequency 
% - dpli
% - permutation entropy
% - hub location
%
% at the following frequency:
% - delta
% - theta
% - alpha
% - beta
%
% at the following epochs (sometime these are not present for the pariticpant):
% - baseline 
% - first hot 
% - cold
% - second hotYacine Mahdid
%
% for all the participants


REPO_LOCATION = '/lustre03/project/6010672/yacine08/eeg-pain-detection/milestones/3_first_draft_paper';
addpath(genpath(REPO_LOCATION)); % need to add the repo to path because matlab is dumb

CONFIG_FILENAME = 'yacine_configuration.json';
configuration = jsondecode(fileread(CONFIG_FILENAME));

%% BELUGA Setup
NEUROALGO_PATH = configuration.neuro_algo_path;
NUM_CORE = configuration.num_cores;

% Add NA library to our path so that we can use it
addpath(genpath(NEUROALGO_PATH));

% Disable this feature (CHECK IF NEEDED)
if configuration.is_cluster == 1
    distcomp.feature( 'LocalUseMpiexec', false ) % This was because of some bug happening in the cluster

    % Create a "local" cluster object
    local_cluster = parcluster('local');

    % Modify the JobStorageLocation to $SLURM_TMPDIR
    pc.JobStorageLocation = strcat('/scratch/YourUsername/', getenv('SLURM_JOB_ID'));

    % Start the parallel pool
    parpool(local_cluster, NUM_CORE)
end

%% Experiment Variable
% Path 
IN_DIR = configuration.in_dir;
FULL_HEADSET_LOCATION = configuration.full_headset_location;
OUT_FILE = strcat(configuration.out_dir, "features_%s.csv");
OUT_LOG = strcat(configuration.out_dir, "logs_", num2str(now*10), ".csv"); 

file_id = fopen(OUT_LOG,'w');
fclose(file_id);

header = ["id", "type", "state"];
bandpass_names = {'delta','theta', 'alpha', 'beta'};
bandpass_freqs = {[1 4], [4 8], [8 13], [13 30]};

% This will be the same throughout the features
features_params = configuration.features_params;

data = load(FULL_HEADSET_LOCATION);
max_location = data.max_location;

%% Iterating over all the participants

% Iterate over all directory since the first two are the '.' and '..' then
% we start at index 3. 
% We will be using parfor to take advantage of compute quebec beluga server
directories = dir(IN_DIR);
parfor id = 3:length(directories)
    folder = directories(id);
    disp(folder.name);
            
 
    out_file_participant = sprintf(OUT_FILE,folder.name);
    write_header(out_file_participant, header, bandpass_names, max_location)
    
    % participant variable init
    p_id = str2num(extractAfter(folder.name,"E"));
    is_healthy = contains(folder.name, 'HE');
    participant_path = strcat(folder.folder,filesep,folder.name);
     

    %% Iterate through the files within the participant folder
    files = dir(participant_path);
    for f_id = 3:length(files)
       filename = files(f_id).name;
       state = is_valid_state(filename, configuration.states);
       
       % 0 in the state means its not a valid state
       % valid state includes: nopain, rest, hot1, cold, hot2
       if state == 0
          continue
       end
       
       %% Load data and calculate feature
       % We need to try/catch the loading of the set file because something
       % there is a problematic file
       disp(filename)
       try 
            recording = load_set(filename, participant_path);
            [features] = calculate_features(recording, features_params, bandpass_freqs, bandpass_names, max_location);
       catch
          disp(strcat("Problem with file: ", filename))
          file_id = fopen(OUT_LOG,'a');
          fpritnf(file_id, strcat("Problem with file: ", filename));
          fclose(file_id);
          continue;
       end
       
       %% Write the features to file
       [num_window, ~] = size(features);
       for w = 1:num_window
           row = features(w,:);
           dlmwrite(out_file_participant, [p_id, is_healthy, state, row], '-append');
       end
       
    end
    
end

% Concatenating all the files into a big table without parfor
OUT_FILE_ALL = sprintf(OUT_FILE, "all");
write_header(OUT_FILE_ALL, header, bandpass_names, max_location)
for id = 3:length(directories)
    folder = directories(id);
    
    disp(folder.name);
    out_file_participant = sprintf(OUT_FILE,folder.name);
    participant_table = readtable(out_file_participant);
    
    table_data = table2array(participant_table);
    [num_window, ~] = size(table_data);
    for w = 1:num_window
        row = table_data(w,:);
        dlmwrite(OUT_FILE_ALL, [row], '-append');
    end

    delete(out_file_participant);
end


function [features] = calculate_features(recording, features_params, bandpass_freqs, bandpass_names, max_location)
% CALCULATE FEATURES: iterate over a recording to calculate the features 
% given the analysis parameters


    %% Parameters unpacking
    % General
    win_size = features_params.general.win_size;
    step_size = features_params.general.step_size;

    % Power
    time_bandwith_product = features_params.power.time_bandwith_product;
    number_tapers = features_params.power.number_tapers;

    % wPLI & dPLI Params
    number_surrogate = features_params.pli.number_surrogate; % Number of surrogate wPLI to create
    p_value = features_params.pli.p_value; % the p value to make our test on

    % Permutation Entropy Params
    embedding_dimension = features_params.pe.embedding_dimension;
    time_lag = features_params.pe.time_lag;

    % Hub Location (HL)
    threshold = features_params.hub_location.threshold; % This is the threshold at which we binarize the graph
    a_degree = features_params.hub_location.a_degree;
    a_bc = features_params.hub_location.a_bc;

    features = [];
    for b_i = 1:length(bandpass_freqs)
        bandpass = bandpass_freqs{b_i};
        name = bandpass_names{b_i};
        fprintf("Calculating Feature at %s\n",name);

        % Power per channels
        [pad_powers] = calculate_power(recording, win_size, step_size, bandpass, max_location);

        % Peak Frequency
        result_sp = na_spectral_power(recording, win_size, time_bandwith_product, number_tapers, bandpass, step_size);
        peak_frequency = result_sp.data.peak_frequency';

        % wPLI
        [pad_avg_wpli] = calculate_wpli(recording, bandpass, win_size, step_size, number_surrogate, p_value, max_location);

        % dPLI
        [pad_avg_dpli] = calculate_dpli(recording, bandpass, win_size, step_size, number_surrogate, p_value, max_location);

        % PE
        [pad_pe] = calculate_pe(recording, win_size, step_size, bandpass, embedding_dimension, time_lag, max_location);

        % HL
        [pad_hl] = calculate_hl(recording, win_size, step_size, bandpass, number_surrogate, p_value, threshold, a_degree, a_bc, max_location);

        features = horzcat(features, pad_powers, peak_frequency, pad_avg_wpli, pad_avg_dpli, pad_pe, pad_hl);
    end
end

function write_header(OUT_FILE, header, bandpass_names, max_location)
    %% Create data set
    % Overwrite the file
    
    delete(OUT_FILE);

    % Write header to the features file
    file_id = fopen(OUT_FILE,'w');
    for i = 1:length(header)
        fprintf(file_id,'%s,', header(i));
    end

    % Write the rest of the header for the channel-wise power
    for b_i = 1:length(bandpass_names)
        bandpass_name = bandpass_names{b_i};

        write_feature_vector(file_id, max_location, bandpass_name, "power")         

        % Peak Frequency
        feature_label = sprintf("peak_freq_%s",bandpass_name);
        fprintf(file_id, '%s,',lower(feature_label));

        write_feature_vector(file_id, max_location, bandpass_name, "wpli")         
        write_feature_vector(file_id, max_location, bandpass_name, "dpli") 
        write_feature_vector(file_id, max_location, bandpass_name, "pe")        
        write_feature_vector(file_id, max_location, bandpass_name, "hl")
    end

    fprintf(file_id,"\n");
    fclose(file_id);
end

function [pad_avg_wpli] = calculate_wpli(recording, bandpass, win_size, step_size, number_surrogate, p_value, max_location)
    result_wpli = na_wpli(recording, bandpass, win_size, step_size, number_surrogate, p_value);
    location = result_wpli.metadata.channels_location;
    avg_wpli = mean(result_wpli.data.wpli,3);
    
    pad_avg_wpli = pad_result(avg_wpli, location, max_location);
end

function [pad_avg_dpli] = calculate_dpli(recording, bandpass, win_size, step_size, number_surrogate, p_value, max_location)
    result_dpli = na_dpli(recording, bandpass, win_size, step_size, number_surrogate, p_value);
    location = result_dpli.metadata.channels_location;
    avg_dpli = mean(result_dpli.data.dpli,3);
    
    pad_avg_dpli = pad_result(avg_dpli, location, max_location);
end

function [pad_powers] = calculate_power(recording, win_size, step_size, bandpass, max_location)
    power_struct = na_topographic_distribution(recording, win_size, step_size, bandpass);
    location = power_struct.metadata.channels_location;
    powers = power_struct.data.power;
    
    pad_powers = pad_result(powers, location, max_location);
end

function [pad_hl] = calculate_hl(recording, win_size, step_size, bandpass, number_surrogate, p_value, threshold, a_degree, a_bc, max_location)
    hl_struct = na_hub_location(recording, bandpass, win_size, step_size, number_surrogate, p_value, threshold, a_degree, a_bc);
    location = hl_struct.metadata.channels_location;
    hl_weights = hl_struct.data.hub_weights;
    
    pad_hl = pad_result(hl_weights, location, max_location);
end

function [pad_pe] = calculate_pe(recording, win_size, step_size, bandpass, embedding_dimension, time_lag, max_location)
    pe_struct = na_permutation_entropy(recording, bandpass, win_size , step_size, embedding_dimension, time_lag);
    location = pe_struct.metadata.channels_location;
    pe = pe_struct.data.normalized_permutation_entropy;
    
    pad_pe = pad_result(pe, location, max_location);
end

function [pad_vector] = pad_result(vector, location, max_location)
% PAD_RESULT : will pad the result with the channels it has missing
% This is used to have a normalized power that has the same number of
% channels for all values. Will put NaN where a channel is missing.

    [num_window,~] = size(vector);
    pad_vector = zeros(num_window, length(max_location));
    for w = 1:num_window
        for l = 1:length(max_location)
            label = max_location(l).labels;

            % The channel may not be in the same order as location
            index = get_label_index(label, location);

            if (index == 0)
                pad_vector(w,l) = NaN; 
            else
                pad_vector(w,l) = vector(w, index);
            end
        end
    end
end

% Function to check if a label is present in a given location
function [label_index] = get_label_index(label, location)
    label_index = 0;
    for i = 1:length(location)
       if(strcmp(label,location(i).labels))
          label_index = i;
          return
       end
    end
end

function write_feature_vector(file_id, max_location, bandpass_name, feature_type)
    for c = 1:length(max_location)
        channel_label = max_location(c).labels;
        feature_label = sprintf("%s_%s_%s",channel_label, bandpass_name, feature_type);
        fprintf(file_id,'%s,', lower(feature_label)); 
    end
end

function [state_id] = is_valid_state(filename, states)
% IS VALID STATE: Check if the filename contains data from a valid state
%
%   Input:
%   filename = the name of the file we would want to load from
%   states = an cell array of string containing permitted state (see
%   configuration.json files for information)
%
%   Output:
%   state_id = the index of the states, again see the configuration for the
%   name that correspond to the id (start at 1 not 0 because its matlab)
    for s = 1:length(states)
       state = states{s};
       if(contains(filename, state))
           state_id = s;
           return
       end
    end
    
    state_id = 0;
end