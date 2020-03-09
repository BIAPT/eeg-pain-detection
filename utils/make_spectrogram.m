function make_spectrogram(data,type)
    analysis_technique = 'Spectrogram';
    
    figure;
    plot(data.frequencies_spectrum, data.baseline_spectrum,'--b', 'LineWidth',2);
    hold on
    plot(data.frequencies_spectrum, data.pain_spectrum,'--r', 'LineWidth',2);
    grid on
    xlabel("Frequency (Hz)");
    ylabel("Power (dB)");
    title(strcat(type," ",analysis_technique, " Baseline vs Hot"));
    % the difference
    diff_spectrum = log(data.baseline_spectrum ./ data.pain_spectrum);
    figure;
    plot(data.frequencies_spectrum, diff_spectrum,'k--', 'LineWidth',2);
    grid on
    legend('Difference');
    xlabel("Frequency (Hz)");
    ylabel("Log Ratio");
    title(strcat(type," ",analysis_technique, " Log Ratio(Baseline vs Hot)"));
end