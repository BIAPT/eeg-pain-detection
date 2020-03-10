%{
    Yacine Mahdid March 09 2020
    This is the processing pipeline to go from raw data to the X and y
    matrix.
%}

%% Setup
% Path 
input_dir = "/media/yacine/Data/pain_and_eeg/all_data/";
output_filename = "/media/yacine/Data/pain_and_eeg/machine_learning_data/data.csv";

% Global Experiment Variable
header = ["id", "type", "avg_alpha_power", "is_hot"];
alpha_band = [8 13];
full_band = [1 50];
rejected_participants = {
    'HE014', 'ME019', ...
    'ME034','ME042', 'ME046', 'ME048', 'ME050', 'ME052', 'ME053', ...
    'ME056', 'ME059', 'ME065'
    };

% Analysis Technique
% Spectrogram
spr_param = struct();
spr_param.window_size = 10;
spr_param.time_bandwith_product = 2;
spr_param.number_tapers = 3;
spr_param.spectrum_window_size = 3; % in seconds
spr_param.step_size = 10; % in seconds

% Permutation Entropy
pe_param = struct();
pe_param.window_size = 10;
pe_param.step_size = 0.01;
pe_param.embedding_dimension = 5;
pe_param.time_lag = 4;

% wPLI & dPLI
pli_param = struct();
pli_param.window_size = 10;
pli_param.number_surrogate = 20; % Number of surrogate wPLI to create
pli_param.p_value = 0.05; % the p value to make our test on
pli_param.step_size = 0.01;

%% Create data set
% Overwrite the file
delete(output_filename);

% Write header to the features file
file_id = fopen(output_filename,'w');
for i = 1:(length(header)-1)
    fprintf(file_id,'%s,',header(i));
end
fprintf(file_id,"%s\n",header(length(header)));
fclose(file_id);

%% Iterating over all the participants
directories = dir(input_dir);

% Iterate over all directory since the first two are the '.' and '..' then
% we start at index 3
for id = 3:length(directories)
    folder = directories(id);
        
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
    
    %disp(strcat('Extracting features from: ', folder.name));
    
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
        return;
    end
    
    
    %% Calculate Features
    
    spectral_power_baseline = na_spectral_power(baseline_recording, ...
        spr_param.window_size, spr_param.time_bandwith_product, ...
        spr_param.number_tapers, spr_param.spectrum_window_size, ...
        alpha_band, spr_param.step_size);
    
    avg_power_baseline = spectral_power_baseline.data.avg_spectrums;
    
    spectral_power_hot = na_spectral_power(hot_pain_recording, ...
        spr_param.window_size, spr_param.time_bandwith_product, ...
        spr_param.number_tapers, spr_param.spectrum_window_size, ...
        alpha_band, spr_param.step_size);    
    
    avg_power_hot = spectral_power_hot.data.avg_spectrums;
   
    
    %% Write the features to file
    for w_i = 1:length(avg_power_baseline)
        dlmwrite(output_filename, [p_id, is_healthy, avg_power_baseline(w_i), 0], '-append');
    end
   
    for w_i = 1:length(avg_power_hot)
        dlmwrite(output_filename, [p_id, is_healthy, avg_power_hot(w_i), 1], '-append');     
    end
  
end


