function H = ButterworthFilter(image_size,center,cutoff_frequency,order)

    % frequencies
    [fx, fy] = meshgrid(1:image_size(2),1:image_size(1));

    % radial frequency
    fr = ((fx-center(2)).^2+(fy-center(1)).^2).^0.5;

    % Butterworth filter
    H = 1./(1+(fr/cutoff_frequency).^(2*order));

end