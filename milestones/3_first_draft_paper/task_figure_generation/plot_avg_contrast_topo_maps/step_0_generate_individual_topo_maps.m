%% Yacine Mahdid 23 September 2020
% This script will generate the contrast topographic map.
% It will generate these contrast: 
% heat1_vs_baseline, cold_vs_baseline, heat2_vs_baseline
% It will generate them for these bandpass:
% alpha, beta, theta, delta
% It will generate them for these type:
% healthy, msk

CONFIG_FILENAME = 'beluga_configuration.json';
configuration = jsondecode(fileread(CONFIG_FILENAME));

%% Experiment Variable

% Paths
IN_DIR = "/media/yacine/Data/pain_and_eeg/all_data/";
FULL_HEADSET_LOCATION = "/home/yacine/Documents/BIAPT/eeg-pain-detection/milestones/.data/full_headset_location.mat";
OUT_PATH = "/home/yacine/Documents/BIAPT/eeg_pain_result/figure_owen/ppt/";
OUT_LOG = strcat(OUT_PATH, "logs_", num2str(now*10), ".csv"); 

file_id = fopen(OUT_LOG,'w');
fclose(file_id);

% This will be the same throughout the features
features_params = configuration.features_params;

headset_data = load(FULL_HEADSET_LOCATION);
max_location = headset_data.max_location;

% General
win_size = features_params.general.win_size;
step_size = features_params.general.step_size;

% Power
time_bandwith_product = features_params.power.time_bandwith_product;
number_tapers = features_params.power.number_tapers;

bandpass_names = {'delta','theta', 'alpha', 'beta'};
bandpass_freqs = {[1 4], [4 8], [8 13], [13 30]};

%% Iterating over all the participants

% Iterate over all directory since the first two are the '.' and '..' then
% we start at index 3. 
% We will be using parfor to take advantage of compute quebec beluga server
directories = dir(IN_DIR);
for id = 3:length(directories)
    folder = directories(id);
    disp(folder.name);
            
    % participant variable init
    p_id = str2num(extractAfter(folder.name,"E"));
    
    % setup the group_name
    is_healthy = contains(folder.name, 'HE');
    if (is_healthy)
        group_name = 'healthy';
    else
        group_name = 'msk';
    end
    
    participant_path = strcat(folder.folder,filesep,folder.name);
     
    %% Iterate through the files within the participant folder
    files = dir(participant_path);
    for f_id = 3:length(files)
       filename = files(f_id).name;
       state_id = is_valid_state(filename, configuration.states);
       
       % 0 in the state means its not a valid state
       % valid state includes: nopain, rest, hot1, cold, hot2
       if state_id == 0
          continue
       end
       
       state_name = erase(configuration.states{state_id}, '.set');
       
       if strcmp(state_name, 'rest') || strcmp(state_name, 'nopain') || strcmp(state_name, 'covas')
            state_name = 'baseline';
       end
       
       %% Load data and calculate feature
       % We need to try/catch the loading of the set file because something
       % there is a problematic file
       disp(filename)
       try 
            recording = load_set(filename, participant_path);
            %% Calculate Topographic Map
            features = [];
            for b_i = 1:length(bandpass_freqs)
                bandpass = bandpass_freqs{b_i};

                bandpass_name = bandpass_names{b_i};
                fprintf("Calculating Feature at %s\n",bandpass_name);

                % Power per channels
                pad_powers = calculate_power(recording, win_size, step_size, bandpass, max_location);
                
                % Save the paded power data
                
                % we have p_id, bandpass_name, group_name
                % name = [group_name]_[bandpass_name]_[state_name]_[p_id]_avg_topo.mat
                out_filename = strcat(OUT_PATH, group_name, '_', bandpass_name, '_', state_name, '_', string(p_id), '_avg_topo.mat');
                
                avg_power = mean(pad_powers);
                save(out_filename, 'avg_power');
            end
            
            
       catch
          disp(strcat("Problem with file: ", filename))
          
          file_id = fopen(OUT_LOG,'a');
          fprintf(file_id, strcat("Problem with file: ", filename,"\n"));
          fclose(file_id);
          continue;
       end
       
       
    end
    
end


function [pad_powers] = calculate_power(recording, win_size, step_size, bandpass, max_location)
    power_struct = na_topographic_distribution(recording, win_size, step_size, bandpass);
    location = power_struct.metadata.channels_location;
    powers = power_struct.data.power;
    
    pad_powers = pad_result(powers, location, max_location);
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
