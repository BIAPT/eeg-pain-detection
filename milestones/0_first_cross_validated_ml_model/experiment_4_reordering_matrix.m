%% The goal here is to draft a functionality to reorder the channels

% The idea is to have a vector of labels that maps to the ordering we want
% to see
%label_order={'Fp1','Fp2','F3','F4','C3','Cz','C4','T5','T6','P3','Pz','P4','O1'}; healthy
%
%label_order={'F3','Fz', 'F4', 'C3','C4','Pz','P4','O1'};
% We are working with the data structure which has reduced_locations

% This is for the full dataset
label_order = {'Fp1','Fp2','F3','Fz','F4','F7','F8','C3','Cz','C4','T3','T4','T5','T6','P3','Pz','P4','O1','O2'};
% Setting up path variables
result_path = "";

type = 'MSK Average Participants';

data = load(strcat(result_path,'MEAVG.mat'));
data = data.result;

data.baseline_wpli = reorder_matrix(data.baseline_wpli, label_order,data.m_location);
data.baseline_dpli = reorder_matrix(data.baseline_dpli, label_order,data.m_location);

data.pain_wpli = reorder_matrix(data.pain_wpli, label_order, data.m_location);
data.pain_dpli = reorder_matrix(data.pain_dpli, label_order, data.m_location);


make_dpli(data,type,label_order);
make_wpli(data,type,label_order);

function [ordered_matrix] = reorder_matrix(matrix, label_order, channels_location)
    % First step is to make a reordering vector
    % We'll iterate over the channel_location and find where it maps to the
    % label_order
    reordering_vector = zeros(1,length(label_order));
    for i = 1:length(channels_location)
        
        % Get the label
        target_label = channels_location(i).labels; 
        % Get where it should be now
        target_index = find_item_index(target_label,label_order);
        % Save it into the vector
        reordering_vector(i) = target_index;
    end
    
    % Second steps is to take the matrix and recreate it
    ordered_matrix = zeros(size(matrix));
    for i = 1:length(matrix)
        new_i = reordering_vector(i);
        for j=1:length(matrix)
            new_j = reordering_vector(j);        new_i = reordering_vector(i);
            ordered_matrix(i,j) = matrix(new_i, new_j);
        end        
    end
    
end

% Helper function to find an item (target) in the label vector
function [index] = find_item_index(target, label_vector)
    index = -1;
    
    for i = 1:length(label_vector)
       if(strcmp(target,label_vector{i}))
          index = i;
          return;
       end
    end
end