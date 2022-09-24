clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))

% Selecciona la imagen que se va a utilizar
caso = 2;

% Lectura de un DICOM de la adquisición LL
if caso==1
    metadata = ReadPhilipsDICOM('data/DICOM/IM_000.dcm',{'MAGNITUDE','PHASE'});
else
    metadata = ReadPhilipsDICOM('data/DICOM/IM_001.dcm',{'MAGNITUDE','PHASE'});
end    
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
P = metadata.PHASE;         % imágenes de fase

% Dimensiones de la imagen
Isz = size(M);

figure,
tiledlayout(3,5,'Padding','compact','TileSpacing','compact')
for fr=1:Isz(3)
    nexttile1600 1600 1000
    imagesc(M(:,:,fr)); axis off; colormap gray
end

% Tiempos de eco
TE = 3.336;
if caso==1
    t0 = 21;
    dt = 66;
else
    t0 = 21;
    dt = 213;
end
t = (t0+TE:dt:dt*Isz(3))';

% Disminuir el tamaño de la imagen
resize=true;
Isz_r = [64 64];
if resize
    Mr = zeros([Isz_r Isz(3)]);
    for i=1:Isz(3)
        Mr(:,:,i) = imresize(M(:,:,i),Isz_r);
    end
else
    Mr = M;
end

% Tamaño de la imagen
Isz = size(Mr);

% Mascara para la estimación de los mapas
mask = sum(Mr, 3) > 2000;

% Parámetros del modelo
fo = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[-2000,-2000,0],...
               'Upper',[2000,2000,4000],...
               'StartPoint',[1600 1600 1000]);
g = fittype('a-2*b*exp(-x/c)','options',fo);

% Estima los valores de T1
T1 = NaN(Isz(1:2));
M0 = NaN(Isz(1:2));
for i=1:Isz(1)
    for j=1:Isz(2)
        if mask(i,j)
            % Arregla valores que deberians er negativos
            M_ = squeeze(Mr(i,j,:));
            idx = find(M_==min(M_));
            M_(1:idx) = -M_(1:idx);
     
            % Ajusta datos al modelo
            f0 = fit(t,M_,g);
            M0(i,j) = f0.a;
            T1(i,j) = f0.c;                
            
            if true
                figure(3)
                subplot 121
                plot(t,M_,'b','LineWidth',2); hold on
                plot(t,f0.a - 2*f0.b*exp(-t/T1(i,j)),'s','MarkerFaceColor','r'); hold off
                legend('Signal','Fit')
                subplot 122
                imagesc(T1);colorbar; caxis([0 1000])
                drawnow
            end                   
            
        end
    end
end

%%
figure(2)
subplot 121
imagesc(M0); colorbar; axis off
subplot 122
imagesc(abs(T1)); colorbar; caxis([0 1500]); axis off
colormap jet
sgtitle('T1 map')
set(gca,'Position',[0.570340909090909,0.110000000000000,0.284644882327108,0.815000000000000])
set(gcf,'Position',[652,528,1173,450])
drawnow
if caso==1
    print('-dpng','-r300','T1_short_TR')
else
    print('-dpng','-r300','T1_long_TR')
end