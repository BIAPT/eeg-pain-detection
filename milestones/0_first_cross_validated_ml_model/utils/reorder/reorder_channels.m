function [r_wpli, r_location, r_regions] = reorder_channels(wpli, location)
%REORDER CHANNELS take a wPLI matrix and a channels location struct and
%reorder the channels (will also implicitly filter because it is using
%scalp only channels file
    
    % Save the original directory and move to the other path
    channel_order = readtable('biapt_egi129.csv');
    
    % Fetch the correct channels location information
    [num_location, labels, regions] = get_num_location(location, channel_order);
    
    % Init the return data structure
    r_wpli = zeros(num_location, num_location);
    r_location = labels;
    r_regions = regions;
    
    % Iterate over all the channels combination (num_channels *
    % num_channels)
    for l1 = 1:length(labels)
       label_1 = labels{l1};
       
        for l2 = 1:length(labels)
            label_2 = labels{l2};
            
            index_1 = get_index_label(location, label_1);
            index_2 = get_index_label(location, label_2);
            
            % If one of the channel doesn't exist we just skip this
            % iteration
            if(index_1 == 0 || index_2 == 0)
               continue 
            end
            
            r_wpli(l1,l2) = wpli(index_1, index_2);
        end
    end
end


function [index] = get_index_label(location, target)
% GET INDEX LABEL will fetch the index of a given label (target) inside the
% location data structure

    index = 0;  
    for l = 1:length(location)
       label = location(l).labels;
       if(strcmp(label,target))
           index = l;
            return 
       end
    end
    
end

function [num_location, labels, regions] = get_num_location(location, total_location)
%GET NUM LOCATION will fetch the stats for the wPLI matrix that match the
%total channels location inside the csv file. This will prevent case where
%there is a channel missing in the data, but the size is still the size of
%total_location

    % Init the return data structure
    num_location = 0;
    labels = {};
    regions = {};
    
    % Iterate through all channels in total location and check if it exist
    % in the current location
    for i = 1:height(total_location)
       label = total_location(i,1).label{1};
       region = total_location(i,2).region{1};

       % If it exist we add information about this region in the return
       % data structure
       if(get_index_label(location, label) ~= 0)
           num_location = num_location + 1;
           labels{end+1} = label;
           regions{end+1} = region;
       end
    end
end
