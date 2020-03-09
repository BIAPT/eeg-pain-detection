% Helper function to create a matrix (for wpli and dpli)
function make_matrix(data, title_name, labels)
    imagesc(data);
    xtickangle(90)
    xticklabels(labels);
    yticklabels(labels);  
    xticks(1:length(labels));
    yticks(1:length(labels));
    colorbar;
    title(title_name);
end