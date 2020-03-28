%% Yacine Mahdid March 28 2020
% This script is solving this task: https://github.com/BIAPT/eeg-pain-detection/issues/12

%% Experiment Variable
IN_DIR = "/media/yacine/Data/pain_and_eeg/all_data/";
OUT_DIR = "/home/yacine/Documents/BIAPT/eeg-pain-detection/projects/.data/";

% We will be looking at either nopain.set or rest.set
rejected_participants = {
    'HE014', 'ME019', ...
    'ME034','ME042', 'ME046', 'ME048', 'ME050', 'ME052', 'ME053', ...
    'ME056', 'ME059', 'ME065'
    };

% Variable to keep track of the largest eeg location
max_num_channels = -1;
max_location = [];

%% Iterating over all the participants
directories = dir(IN_DIR);

% Iterate over all directory since the first two are the '.' and '..' then
% we start at index 3
for id = 3:length(directories)
    folder = directories(id);
        
    % We skip participants that are problematic
    if(ismember(folder.name, rejected_participants))
        continue 
    end
        
    % load baseline recording if nopain.set doesn't exist  will load rest.set
    participant_path = strcat(folder.folder,filesep,folder.name);
    try 
        baseline_name = strcat(folder.name,'_nopain.set');
        baseline_recording = load_set(baseline_name, participant_path);
    catch
        baseline_name = strcat(folder.name,'_rest.set');
        baseline_recording = load_set(baseline_name, participant_path);
    end
    

    
    % Get the location of channels data structure
    disp(baseline_name);
    location = baseline_recording.channels_location;
    if (length(location) > max_num_channels)
        max_num_channels = length(location);
        max_location = location;
    end
end

%% Saving the location structure
filename = strcat(OUT_DIR, "full_headset_location.mat");
save(filename, 'max_location');