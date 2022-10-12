clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))


%% LECTURA DE RAW DATA
K = squeeze(readListData('data/flyback_yes/DIXON_2P/RAW/raw_000.list'));
K = K(1:2:end,:,:,:);   % corrige sobremuestreo

% Tamaño de la imagen, cantidad de bobinas y frames
Isz = size(K,[1 2]);
Nechos = size(K,3);
Ncoils = size(K,4);

figure,
for j=1:Nechos
    for i=1:Ncoils
        subplot(2,4,(j-1)*4 + i)
        imagesc(abs(K(:,:,j,i))); axis off; colormap gray;
    end
end
pause

% Reconstrucción de las imágenes
I = ktoi(K, [1 2]);

figure,
for j=1:Nechos
    for i=1:Ncoils
        subplot(2,4,(j-1)*4 + i)
        imagesc(abs(I(:,:,j,i))); axis off; colormap gray; caxis([0 0.5])
    end
end
pause


%% LECTURA DE IMAGEN DICOM
% Lectura de un DICOM de la adquisición Dixon de 2 puntos con flyback=yes
metadata = ReadPhilipsDICOM('data/flyback_yes/DIXON_2P/DICOM/IM_000.dcm',{'MAGNITUDE','REAL','IMAGINARY'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
R = metadata.REAL;          % imágenes de la parte real
I = metadata.IMAGINARY;     % imágenes de la parte imaginaria

% Reconstruye imagen compleja para obtener la fase
I = metadata.REAL + 1j*metadata.IMAGINARY;
P = angle(I);

% Muestra la fase de las imágenes
figure,
subplot 121
imagesc(P(:,:,1))
subplot 122
imagesc(P(:,:,2))
pause


%% PHASE UNWRAPPING
% Corrije los artefactos de fase en ambos ecos
P(:,:,1) = unwrap2(P(:,:,1),'Mask',true(size(P(:,:,2))),'PixelSize',[1 1],...
                   'Seed','auto');
P(:,:,2) = unwrap2(P(:,:,2),'Mask',true(size(P(:,:,1))),'PixelSize',[1 1],...
                   'Seed','auto');

% Muestra imágenes corregidas
figure,
subplot 121
imagesc(P(:,:,1)); %caxis([-pi pi])
subplot 122
imagesc(P(:,:,2)); %caxis([-pi pi])
pause


%% ROI PARA COMPARACIÓN
% Dibuja un ROI en la imagen y estima el valor promedio de los pixeles en su interior
figure,
imagesc(P(:,:,1))
h = imellipse(gca);

% Crea la máscara y estima el promedio
roi = h.createMask;
P1 = P(:,:,1);
mean(P1(roi))

