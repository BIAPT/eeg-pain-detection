%% Yacine Mahdid May 26
% We basically needs to calculate Power, wPLI and peak frequency
% the first two need to be calculated at delta, theta, alpha, beta


%% BELUGA Setup
NEUROALGO_PATH = "/lustre03/project/6010672/yacine08/NeuroAlgo";
NUM_CORE = 40;

% Add NA library to our path so that we can use it
addpath(genpath(NEUROALGO_PATH));

% Disable this feature
distcomp.feature( 'LocalUseMpiexec', false )
% Create a "local" cluster object
local_cluster = parcluster('local')

% Modify the JobStorageLocation to $SLURM_TMPDIR
pc.JobStorageLocation = strcat('/scratch/YourUsername/', getenv('SLURM_JOB_ID'))

% Start the parallel pool
parpool(local_cluster, NUM_CORE)

%% Experiment Variable
% Path 
IN_DIR = "/lustre03/project/6010672/yacine08/eeg_pain_data/";
FULL_HEADSET_LOCATION = "/lustre03/project/6010672/yacine08/eeg-pain-detection/projects/.data/full_headset_location.mat";
OUT_FILE = "/lustre03/project/6010672/yacine08/eeg_pain_result/features_%s.csv";

% Global Experiment Variable
rejected_participants = {
    'HE014','HE007', 'ME019', ...
    'ME034','ME040','ME042', 'ME046', 'ME048', 'ME050', 'ME052', 'ME053', ...
    'ME056', 'ME059', 'ME065'
    };

header = ["id", "type", "is_hot"];
bandpass_names = {'delta','theta', 'alpha', 'beta'};
bandpass_freqs = {[1 4], [4 8], [8 13], [13 30]};

% This will be the same throughout the features
WIN_SIZE = 10;
STEP_SIZE = 0.1;

% Spectrogram Params
time_bandwith_product = 2;
number_tapers = 3;

% wPLI Params
number_surrogate = 20; % Number of surrogate wPLI to create
p_value = 0.05; % the p value to make our test on

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
        
    % We skip participants that are problematic
    if(ismember(folder.name, rejected_participants))
        continue 
    end
    
    % participant variable init
    p_id = str2num(extractAfter(folder.name,"E"));
    is_healthy = contains(folder.name, 'HE');
    participant_path = strcat(folder.folder,filesep,folder.name);
    
    baseline_name = sprintf('%s_nopain.set',folder.name);
    hot_pain_name = sprintf('%s_hot1.set',folder.name);
    
    % load baseline recording, if nopain doesn't exist  will load rest
    % instead
    try
        baseline_recording = load_set(baseline_name, participant_path);
    catch
        baseline_name = sprintf('%s_rest.set',folder.name);
        baseline_recording = load_set(baseline_name, participant_path);
    end
    
    
    % If there is a problem here it means that there is a datapoint missing
    % Most problematic participant have been added to the rejected
    % participants list
    try
        hot_pain_recording = load_set(hot_pain_name, participant_path);
    catch
        printf("Should remove participant %s", hot_pain_name);
        continue;
    end    

    %% Calculate Features
    recordings = { baseline_recording, hot_pain_recording };
    labels = {0, 1};
    for l_i = 1:length(recordings)
        recording = recordings{l_i};
        label = labels{l_i};
        
        features = [];
        for b_i = 1:length(bandpass_freqs)
            bandpass = bandpass_freqs{b_i};
            name = bandpass_names{b_i};
            fprintf("Calculating Feature at %s\n",name);

            % Power per channels
            [pad_powers] = calculate_power(recording, WIN_SIZE, STEP_SIZE, bandpass, max_location);
            
            % Peak Frequency
            result_sp = na_spectral_power(recording, WIN_SIZE, time_bandwith_product, number_tapers, bandpass, STEP_SIZE);
            peak_frequency = result_sp.data.peak_frequency';
            
            % wPLI
            result_wpli = na_wpli(recording, bandpass, WIN_SIZE, STEP_SIZE, number_surrogate, p_value);
            [pad_avg_wpli] = calculate_wpli(recording, bandpass, WIN_SIZE, STEP_SIZE, number_surrogate, p_value, max_location);

            features = horzcat(features, pad_powers, peak_frequency, pad_avg_wpli);
        end
        
         %% Write the features to file
        [num_window, ~] = size(features);
        for w = 1:num_window
            row = features(w,:);
            dlmwrite(out_file_participant, [p_id, is_healthy, label, row], '-append');
        end
        
    end
end

% Concatenating all the files into a big table without parfor
OUT_FILE_ALL = sprintf(OUT_FILE, "all");
write_header(OUT_FILE_ALL, header, bandpass_names, max_location)
for id = 3:length(directories)
    folder = directories(id);
    
    % We skip participants that are problematic
    if(ismember(folder.name, rejected_participants))
        continue 
    end
    
    disp(folder.name);
    out_file_participant = sprintf(OUT_FILE,folder.name);
    participant_table = readtable(out_file_participant);
    
    table_data = table2array(participant_table);
    [num_window, ~] = size(table_data);
    for w = 1:num_window
        row = table_data(w,:);
        dlmwrite(OUT_FILE_ALL, [row], '-append');
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

        % Power Across Channels
        for c = 1:length(max_location)
            channel_label = max_location(c).labels;
            feature_label = sprintf("%s_%s_power",channel_label, bandpass_name);
            fprintf(file_id,'%s,', lower(feature_label)); 
        end   

        % Peak Frequency
        feature_label = sprintf("peak_freq_%s",bandpass_name);
        fprintf(file_id, '%s,',lower(feature_label));

        % wPLI Across Channels
        for c = 1:length(max_location)
            channel_label = max_location(c).labels;
            feature_label = sprintf("%s_%s_wpli",channel_label, bandpass_name);
            fprintf(file_id,'%s,', lower(feature_label)); 
        end     
    end

    fprintf(file_id,"\n");
    fclose(file_id);
end

function [pad_avg_wpli] = calculate_wpli(recording, bandpass, win_size, step_size, number_surrogate, p_value, max_location)
    result_wpli = na_wpli(recording, bandpass, win_size, step_size, number_surrogate, p_value);
    location = result_wpli.metadata.channels_location;
    avg_wpli = mean(result_wpli.data.wpli,3);
    
    [num_window,~] = size(avg_wpli);
    pad_avg_wpli = zeros(num_window, length(max_location));
    for w = 1:num_window
       pad_avg_wpli(w,:) = pad_result(avg_wpli(w,:), location, max_location);
    end
end

function [pad_powers] = calculate_power(recording, win_size, step_size, bandpass, max_location)
    power_struct = na_topographic_distribution(recording, win_size, step_size, bandpass);
    location = power_struct.metadata.channels_location;
    powers = power_struct.data.power;
    
    [num_window, ~] = size(powers);
    pad_powers = zeros(num_window,length(max_location));
    for w = 1:num_window
        pad_powers(w,:) = pad_result(powers(w,:), location, max_location);
    end
end

function [p_power] = pad_result(power, location, max_location)
% PAD_RESULT : will pad the result with the channels it has missing
% This is used to have a normalized power that has the same number of
% channels for all values. Will put NaN where a channel is missing.
    p_power = zeros(1, length(max_location));
    for l = 1:length(max_location)
        label = max_location(l).labels;
        
        % The channel may not be in the same order as location
        index = get_label_index(label, location);
        
        if (index == 0)
            p_power(l) = NaN; 
        else
            p_power(l) = power(index);
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