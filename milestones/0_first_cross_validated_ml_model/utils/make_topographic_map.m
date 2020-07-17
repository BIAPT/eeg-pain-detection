function make_topographic_map(data,type)
    figure;
    analysis_technique = "Alpha Power";
    axe1 = subplot(1,3,1);
    topographic_map(data.baseline_td,data.m_location);
    title(strcat(type," ",analysis_technique, " Baseline"));
    axe2 = subplot(1,3,2);
    topographic_map(data.pain_td, data.m_location);
    title(strcat(type," ",analysis_technique, " Hot"));
    axe3 = subplot(1,3,3);
    diff_td = log(data.baseline_td ./ data.pain_td);
    topographic_map(diff_td,data.m_location);
    title(strcat(type," ",analysis_technique, " Log Ratio (Baseline vs Hot)"));
    % Add in the colorbar
    colormap(axe1,'jet');
    colormap(axe2, 'jet');
    colormap(axe3, 'hot');
end
