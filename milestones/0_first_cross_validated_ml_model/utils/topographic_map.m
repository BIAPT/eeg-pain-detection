function topographic_map(data,location)
    topoplot(data,location,'maplimits','absmax', 'electrodes', 'off');
    min_color = min(data);
    max_color = max(data);
    caxis([min_color max_color])
    colorbar;
end