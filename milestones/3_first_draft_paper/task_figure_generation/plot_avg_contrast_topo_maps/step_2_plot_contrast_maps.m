%% Yacine Mahdid Septembre 23 2020
% The goal of this script is to generate the average participant for each
% condition.
% The name of the files to load is:
% name = [group_name]_[bandpass_name]_[state_name]_[p_id]_avg_topo.mat


%% Experiment Variables
IN_PATH = "/home/yacine/Documents/BIAPT/eeg_pain_result/figure_owen/avg_ppt/";
OUT_PATH = "/home/yacine/Documents/BIAPT/eeg_pain_result/figure_owen/plot/";
FULL_HEADSET_LOCATION = "/home/yacine/Documents/BIAPT/eeg-pain-detection/milestones/.data/full_headset_location.mat";

groups = {'healthy', 'msk'};
bandpass_names = {'delta','theta', 'alpha', 'beta'};
state_names = {'hot1','cold','hot2'};
suffix = "_avg_topo.mat";

headset_data = load(FULL_HEADSET_LOCATION);
max_location = headset_data.max_location;

for g_i = 1:length(groups)
   group_name = groups{g_i};
   maximum = maximums(g_i);    
   
   
   for f_i = 1:length(bandpass_names)
       bandpass_name = bandpass_names{f_i};
       
       
       baseline_name = strcat(IN_PATH, group_name,'_', bandpass_name, '_', "baseline", suffix);
       data = load(baseline_name);
       baseline_power = data.avg_power;
       
       for s_i = 1:length(state_names)
            state_name = state_names{s_i};
            
           
            state_filename = strcat(IN_PATH, group_name,'_', bandpass_name, '_', state_name, suffix);
            data = load(state_filename);
            state_power = data.avg_power;
            
            contrast_power = state_power - baseline_power;
            
            title_name = strcat("Power at ", group_name, " ", bandpass_name, " ", state_name, " against baseline");
            fig = plot_topo_map(contrast_power, title_name, max_location);
            
            % Save the average power for this group,bandpass and state
            out_filename = strcat(OUT_PATH, group_name,'_', bandpass_name, '_', state_name, '_vs_baseline.png');
            saveas(fig, out_filename)
            delete(fig)
            
       end
   end
end

function [fig] = plot_topo_map(weight, title_name, channels_location)
% Helper function to plot the topographic map using eeglab topoplot
    fig = figure;
    title(title_name);
    topoplot(weight,channels_location,'maplimits','absmax', 'electrodes', 'off');
    colorbar;
    colormap('jet');
    caxis([min(weight) max(weight)]);
end