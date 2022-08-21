function [image] = ktoi(image, dimensions)

if nargin < 2
    image = fftshift(ifftn(ifftshift(image)));
else
    for d=1:numel(dimensions)
        image = fftshift(ifft(ifftshift(image),[],dimensions(d)));
    end
end