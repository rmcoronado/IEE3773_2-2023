clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))


%% LECTURA DE IMAGEN DICOM
% Lee imagen de magnitud
metadata = ReadPhilipsDICOM('data/2/DICOM/IM_0048',{'MAGNITUDE'});
M = metadata.MAGNITUDE;          % imagen de magnitud

figure(1)
imagesc(M(:,:,1))
colormap gray

% Tamaño del pixel [mm]
pxsz = metadata.DICOMInfo.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.PixelSpacing; 

% Tiempos de adquisición de cada frame
Nfr = size(M,3);    % Nro. de frames
t = zeros([1 Nfr]); % tiempos de adquisición (ms)
for i=1:Nfr
    item = sprintf('Item_%d',i);
    t(i) = metadata.DICOMInfo.PerFrameFunctionalGroupsSequence.(item).CardiacSynchronizationSequence.Item_1.NominalCardiacTriggerDelayTime;
end

% Dibuja un ROI en la imagen y estima el valor promedio de los pixeles en su interior
figure,
imagesc(M(:,:,1))
h = imellipse(gca);

% Crea la máscara y estima el promedio
roi = h.createMask;
M1 = M(:,:,1);
mean(M1(roi))