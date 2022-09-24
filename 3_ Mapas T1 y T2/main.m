clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))

%% Imágenes Look-Locker
% Lee raw data de una secuencia Look-Locker
K = squeeze(readListData('data/RAW/raw_000.list'));
K = K(1:2:end,:,:,:);   % corrige sobremuestreo

% Tamaño de la imagen, cantidad de bobinas y frames
Isz = size(K,[1 2]);
Nfr = size(K,3);
Ncoils = size(K,4);

% Del espacio K a la imagen (versión ruidosa)
I_noisy = ktoi(K, [1 2]);

% Remueve las altas frecuencias del espacio K y reconstruye una imagen
% suavizada
Wr = WindowFilter(Isz(1), 0.6, 0.3, 'Tukey');      % filtro en dimension de lectura
Wc = WindowFilter(Isz(2), 0.6, 0.3, 'Tukey');      % filtro en dimension de fase
I = ktoi((Wr.weights'*Wc.weights).*K, [1 2]);    % múltiples bobinas

figure(1)
tiledlayout(2,6,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I_noisy(:,:,fr,coil))); axis off; colormap gray,
end
sgtitle('noisy LL')
pause

figure(2)
tiledlayout(2,6,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I(:,:,fr,coil))); axis off; colormap gray
endI = ktoi((Wr.weights'*Wc.weights).*K, [1 2]);    % múltiples bobinas
sgtitle('filtered LL')
pause

% A partir de un punto elegido por el usuario grafica la variación de 
% la señal a través del tiempo
figure,
imagesc(abs(I(:,:,1,coil)))
sgtitle('Seleccione algunos pixeles sobre el cerebro')
[cols,rows] = getpts(gca);
close(gcf)

figure,
for i=1:numel(cols)
    plot(21:66:Nfr*66,squeeze(real(I(round(rows(i)),round(cols(i)),:,coil))),'LineWidth',2); hold on
end
hold off
pause


% Lectura de un DICOM de la adquisición Look-Locker
metadata = ReadPhilipsDICOM('data/DICOM/IM_000.dcm',{'MAGNITUDE','PHASE'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
P = metadata.PHASE;         % imágenes de fase

figure,
tiledlayout(2,6,'Padding','compact','TileSpacing','compact')
for fr=1:Nfr
    nexttile
    imagesc(M(:,:,fr)); axis off; colormap gray
end
sgtitle('LL from DICOMs')
pause



%% Imágenes Multi-echo
% Lee raw data de una secuencia Multi-echo
K = squeeze(readListData('data/RAW/raw_002.list'));
K = K(1:2:end,:,:,:);   % corrige sobremuestreo

% Tamaño de la imagen, cantidad de bobinas y frames
Isz = size(K,[1 2]);
Nfr = size(K,3);
Ncoils = size(K,4);

% Del espacio K a la imagen
I = ktoi(K, [1 2]);
Itmp = I;
I(:,1:Isz(2)/2,:,:) = Itmp(:,Isz(2)/2+1:end,:,:);
I(:,Isz(2)/2+1:end,:,:) = Itmp(:,1:Isz(2)/2,:,:);

figure,
tiledlayout(2,4,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I(:,:,fr,coil))); axis off; colormap gray
%     title(sprintf('TE = %d ms',TE(fr)))
end
sgtitle('ME from raw data')
pause


% Lectura de un DICOM de la adquisición Multi-echo
metadata = ReadPhilipsDICOM('data/DICOM/IM_002.dcm',{'MAGNITUDE','PHASE'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
P = metadata.PHASE;         % imágenes de fase

figure,
tiledlayout(2,4,'Padding','compact','TileSpacing','compact')
for fr=1:Nfr
    nexttile
    imagesc(M(:,:,fr)); axis off; colormap gray
end
sgtitle('ME from DICOM')