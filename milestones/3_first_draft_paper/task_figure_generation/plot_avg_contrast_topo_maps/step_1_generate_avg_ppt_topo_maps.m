%% Yacine Mahdid Septembre 23 2020
% The goal of this script is to generate the average participant for each
% condition.
% The name of the files to load is:
% name = [group_name]_[bandpass_name]_[state_name]_[p_id]_avg_topo.mat
                

%% Experiment Variables
IN_PATH = "/home/yacine/Documents/BIAPT/eeg_pain_result/figure_owen/ppt/";
OUT_PATH = "/home/yacine/Documents/BIAPT/eeg_pain_result/figure_owen/avg_ppt/";
groups = {'healthy', 'msk'};
bandpass_names = {'delta','theta', 'alpha', 'beta'};
state_names = {'baseline','hot1','cold','hot2'};
maximums = [30, 121];
suffix = "_avg_topo.mat";

for g_i = 1:length(groups)
   group_name = groups{g_i};
   maximum = maximums(g_i);    
   
   for f_i = 1:length(bandpass_names)
       bandpass_name = bandpass_names{f_i};
       
       for s_i = 1:length(state_names)
            state_name = state_names{s_i};

            avg_power = zeros(1,19);
            for p_i = 1:maximum
                p_id = string(p_i); 
                ppt_filename = strcat(IN_PATH, group_name, '_', bandpass_name, '_', state_name, '_', p_id, suffix);
                    
               try 
                    data = load(ppt_filename);
                    avg_power = [avg_power; data.avg_power];
               catch
                    disp(strcat("Problem with file: ", ppt_filename))
                    continue;
               end
            end
            
            avg_power = mean(avg_power, 'omitnan');
            
            % Save the average power for this group,bandpass and state
            out_filename = strcat(OUT_PATH, group_name,'_', bandpass_name, '_', state_name, suffix);
            save(out_filename, 'avg_power');
            
       end
   end
end