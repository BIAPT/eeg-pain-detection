%% Yacine Mahdid May 31 2020
% The goal of this script is to generate the topographic maps of their
% importance for the classification of pain/no-pain

FULL_HEADSET_LOCATION = "/home/yacine/Documents/BIAPT/eeg-pain-detection/projects/.data/full_headset_location.mat";
FEATURE_WEIGHT_LOCATION = "/home/yacine/Documents/BIAPT/eeg_pain_result/channels_importance.csv";

data = load(FULL_HEADSET_LOCATION);
channel_location = data.max_location;
channel_weights = readtable(FEATURE_WEIGHT_LOCATION);

% Healthy
weights = get_weight_type(channel_weights, "BOTH");
plot_topo_map(weights, "Weight per Channel both", channel_location, 'hot');


function weight = get_weight_type(channel_weights, type)
    weight = [];
    for i = 1:height(channel_weights)
       if strcmp(channel_weights.participant_type{i}, type)
           weight = [weight, channel_weights.weight(i)];
       end
    end
end

function plot_topo_map(weight, title_name, channels_location, color)
%PLOT_MOTIF Summary of this function goes here
%   The frequency here is for a single motif
    figure;
    title(title_name);
    topoplot(weight,channels_location,'maplimits','absmax', 'electrodes', 'off');
    colorbar;
    colormap(color);
end