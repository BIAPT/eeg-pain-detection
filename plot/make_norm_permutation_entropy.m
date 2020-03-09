function make_norm_permutation_entropy(data,type)
    figure;
    analysis_technique = "Alpha Permutation Entropy";
    axe1 = subplot(1,3,1);
    topographic_map(data.baseline_norm_pe,data.m_location);
    title(strcat(type," ",analysis_technique, " Baseline"));
    axe2 = subplot(1,3,2);
    topographic_map(data.pain_norm_pe, data.m_location);
    title(strcat(type," ",analysis_technique, " Hot"));
    axe3 = subplot(1,3,3);
    diff_norm_pe = log(data.baseline_norm_pe ./ data.pain_norm_pe);
    topographic_map(diff_norm_pe,data.m_location);
    title(strcat(type," ",analysis_technique, " Log Ratio (Baseline vs Hot)"));
    % Add in the colorbar
    colormap(axe1,'copper');
    colormap(axe2, 'copper');
    colormap(axe3, 'hot');
end
