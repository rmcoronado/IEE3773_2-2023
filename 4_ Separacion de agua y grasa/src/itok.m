function [image] = itok(image, dimensions)

if nargin < 2
    image = ifftshift(fftn(ifftshift(image)));
else
    for d=1:numel(dimensions)
        image = ifftshift(fft(ifftshift(image),[],dimensions(d)));
    end
end