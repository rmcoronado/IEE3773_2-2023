clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))


%% CARGA DE RAW DATA
% Lee el raw data de la adquisición con la bobina de cuerpo completo
% (sólo 1 bobina)
Kb = readListData('data/raw_002.list');
Kb = squeeze(Kb(1:2:end,:,1));

% Lee el raw data y elimina las dimensiones redundates de la adquisición
% con múltiples bobinas
K = readListData('data/raw_001.list');
K = squeeze(K);

% Elimina el 2d slice y NSA de la adquisición
% (La adquisición de las imágenes se hizo con 2 slices y 2 NSA. Esto
% quiere decir, que se adquirieron 2 cortes del cerebro en distintas 
% posiciones 2 veces cada uno para mejorar el SNR de la
% imagen final. Para hacer la reconstrucción de los datos nos basta con
% considerar sólo 1 slice y 1 NSA)
K = squeeze(K(:,:,1,1,:));   % dim=[kx,ky,nb_slices,NSAs,nb_coils]

% Elimina el sobremuestreo
K = K(1:2:end,:,:);


%% DEL ESPACIO K A LA IMAGEN
I = ktoi(K, [1 2]);    % múltiples bobinas
Ib = ktoi(Kb, [1 2]); % cuerpo completo

% Corrección múltiples bobinas
Itmp = I;
I(:,1:115,:) = Itmp(:,116:end,:);    
I(:,116:end,:) = Itmp(:,1:115,:);

% Corrección cuerpo completo
Itmp = Ib;
Ib(:,1:115) = Itmp(:,116:end);    
Ib(:,116:end) = Itmp(:,1:115);

% Tamaño de la imagen y número de bobinas
Isz    = size(I,[1 2]);
Ncoils = size(I,3);

% Imagen adquirida por cada bobina + cuerpo completo
figure,
tiledlayout(3,4,'Padding','compact','TileSpacing','compact')
for i=1:Ncoils
    nexttile(i)
    imagesc(abs(I(:,:,i))); caxis([0 1])
    title(sprintf('Bobina %d',i))
    axis off
end
nexttile(12)
imagesc(abs(Ib)); caxis([0 0.5])
title('Cuerpo completo')
axis off
colormap gray


%% SENSIBILIDAD DE LAS BOBINAS
% Como la imagen adquirida con la bobina de cuerpo completo es muy ruidosa,
% la máscara del cerebro la obtendremos con las adquisiciones de cada
% bobina
mask = false(size(I,[1 2]));
for coil=1:Ncoils
    mask = or(mask, abs(I(:,:,coil)) > 0.15);
end

% Elimina de la máscara aquellos pixeles que no están conectados
h = [0 1 0; 1 0 0; 0 0 0];
tmp = false(Isz(1:2));
for k = 1:4
    tmp(:,:,k) = conv2(double(mask),h,'same')==2;
    h = rot90(h);
end
mask = any(tmp,3) & mask;

% Permite hacer crecer la máscara de manera similar a un algoritmo de RG
h = [0 1 0; 1 0 1; 0 1 0];
mask_rg = mask;
for k = 1:100
    mask_rg = conv2(double(mask_rg),h,'same');
end
mask_rg = mask_rg/max(mask_rg(:)) > 0.05;

figure,
subplot 121
imagesc(mask)
subplot 122
imagesc(mask_rg)


% Estima las sensibilidades usando la función gridfit
[X,Y] = meshgrid(1:Isz(2),1:Isz(1));
Sxy = I./Ib;
S = zeros(size(Sxy));
for coil=1:Ncoils
    Sxy_i = Sxy(:,:,coil);
    S(:,:,coil) = mask_rg.*gridfit(X(mask),Y(mask),Sxy_i(mask),...
                    1:Isz(2),1:Isz(1),'interp','bilinear',...
                    'regularizer','springs','smoothness',50);
end


% Muestra sensibilidades estimadas
figure,
tiledlayout(2,4,'Padding','compact','TileSpacing','compact')
for i=1:Ncoils
    nexttile(i)
    imagesc(abs(S(:,:,i)));
    axis off
end