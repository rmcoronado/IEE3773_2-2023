clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))

% Lectura de un DICOM de la adquisición LL
metadata = ReadPhilipsDICOM('data/DICOM/IM_003.dcm',{'MAGNITUDE','PHASE'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
P = metadata.PHASE;         % imágenes de fase

% Dimensiones de la imagen
Isz = size(M);

figure,
tiledlayout(3,3,'Padding','compact','TileSpacing','compact')
for fr=1:Isz(3)
    nexttile
    imagesc(M(:,:,fr)); axis off; colormap gray
end

% Tiempos de eco
TE = 20;
t = TE:TE:TE*Isz(3);

% Disminuir el tamaño de la imagen
resize=false;
Isz_r = [64 64];
if resize
    Mr = zeros([Isz_r Isz(3)]);
    for i=1:Isz(3)
        Mr(:,:,i) = imresize(M(:,:,i),Isz_r);
    end
else
    Mr = M;
end
Isz = size(Mr);

% Mascara para la estimación de los mapas
mask = sum(Mr, 3) > 1000;

% Construye matriz A para el ajuste de los datos
A = zeros(2,2);
A(1,1) = Isz(3);
A(1,2) = -sum(t);
A(2,1) = sum(t);
A(2,2) = -sum(t.*t);

f = zeros(2,1);

% Estima los valores de T2
T2 = NaN(Isz(1:2));
M0 = NaN(Isz(1:2));
for i=1:Isz(1)
    for j=1:Isz(2)
        if mask(i,j)
            f(1) = sum(log(squeeze(Mr(i,j,:))));
            f(2) = sum(t(:).*log(squeeze(Mr(i,j,:))));            
%             b = (A'*A)\(A'*f);
            b = A\f;
            M0(i,j) = exp(b(1));
            T2(i,j) = 1/b(2);

            if false
                figure(3)
                plot(t,squeeze(M(i,j,:)),'b','LineWidth',2); hold on
                plot(t,M0(i,j)*exp(-t/T2(i,j)),'s','MarkerFaceColor','r'); hold off
                legend('Signal','Fit')
                drawnow
            end            
            
        end
    end
end

figure(2)
subplot 121
imagesc(M0); colorbar; axis off
subplot 122
imagesc(abs(T2)); colorbar; caxis([0 300]); axis off
colormap jet
sgtitle('T2 map')
set(gca,'Position',[0.570340909090909,0.110000000000000,0.284644882327108,0.815000000000000])
set(gcf,'Position',[652,528,1173,450])
print('-dpng','-r300','T2_non_weighted')