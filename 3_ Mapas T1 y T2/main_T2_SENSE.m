clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))

%% Imágenes Look-Locker
% Lee raw data de una secuencia Look-Locker
K = squeeze(readListData('data/RAW/raw_003.list'));
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
I = ktoi((Wr.weights'*Wc.weights).*K, [1 2]);      % múltiples bobinas

%%
% Corrección múltiples bobinas
Itmp = I_noisy;
I_noisy(:,1:80,:) = Itmp(:,81:end,:);    
I_noisy(:,81:end,:) = Itmp(:,1:80,:);

Itmp = I;
I(:,1:80,:) = Itmp(:,81:end,:);    
I(:,81:end,:) = Itmp(:,1:80,:);

figure,
tiledlayout(2,4,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I_noisy(:,:,fr,coil))); axis off; colormap gray,
end

figure,
tiledlayout(2,4,'Padding','compact','TileSpacing','compact')
coil=2;
for fr=1:Nfr
    nexttile
    imagesc(abs(I(:,:,fr,coil))); axis off; colormap gray
end


%% SENSE
% Como la imagen adquirida con la bobina de cuerpo completo es muy ruidosa,
% la máscara del cerebro la obtendremos con las adquisiciones de cada
% bobina
mask = false(size(I,[1 2]));
for coil=1:Ncoils
    mask = or(mask, abs(I(:,:,coil,1)) > 0.015*max(abs(I(:))));
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
for k = 1:20
    mask_rg = conv2(double(mask_rg),h,'same');
end
mask_rg = mask_rg/max(mask_rg(:)) > 0.05;

figure,
subplot 121
imagesc(mask)
subplot 122
imagesc(mask_rg)

% Estima las sensibilidades usando la función gridfit
fr = 3;
Isqr = sqrt(sum(squeeze(I(:,:,fr,:)).^2, 3));
[X,Y] = meshgrid(1:Isz(2),1:Isz(1));
Sxy = squeeze(abs(I(:,:,fr,:)))./repmat(Isqr,[1 1 8]);
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


%% COMBINACION DE LAS BOBINAS
% Imagen combinada
I_sense = zeros(size(I,[1 2 3]));

% Estimación inicial de la solución
x0 = zeros(size(I,[1 2]));%Isqr;

% Parámetros de la optimización
max_i  = 200;
tol    = 1e-6;
show = false;

for fr = 1:size(I,3)
    % Construcción de B
    B = itok(squeeze(I(:,:,fr,:)),[1 2]);

    % Estimación usando CG
    [Isense_cg, history_cg] = opt_gradient(1,S,B,x0,max_i,tol,'cg',show,mask);

    % Plot results
    figure,
    subplot 121
    imagesc(abs(Isqr)); caxis([0 0.5*max(abs(Isqr(:)))])
    subplot 122
    imagesc(abs(Isense_cg)); caxis([0 0.5*max(abs(Isense_cg(mask)))])
    colormap gray
    drawnow
    
    I_sense(:,:,fr) = Isense_cg;
end


%% MAPA T2
% Magnitud de la imagen
M = abs(I_sense);

figure,
imagesc(M(:,:,1))

% Tiempos de eco
TE = 20;
t = TE:TE:TE*size(M,3);

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
mask = sum(Mr, 3) > 1;

% Construye matriz A para el ajuste de los datos
A = zeros(2,2);
f = zeros(2,1);

% Estima los valores de T2
T2 = NaN(Isz(1:2));
M0 = NaN(Isz(1:2));
for i=1:Isz(1)
    for j=1:Isz(2)
        if mask(i,j)
            A(1,1) = sum(squeeze(Mr(i,j,:)));
            A(1,2) = -sum(squeeze(Mr(i,j,:)).*t(:));
            A(2,1) = sum(squeeze(Mr(i,j,:)).*t(:));
            A(2,2) = -sum(squeeze(Mr(i,j,:)).*t(:).^2);
            f(1) = sum(squeeze(Mr(i,j,:)).*log(squeeze(Mr(i,j,:))));
            f(2) = sum(squeeze(Mr(i,j,:)).*t(:).*log(squeeze(Mr(i,j,:))));            
            b = (A'*A)\(A'*f);
%             b = A\f;
            M0(i,j) = exp(b(1));
            T2(i,j) = 1/b(2);
            
            if false
                figure(3)
                plot(t,squeeze(Mr(i,j,:)),'b','LineWidth',2); hold on
                plot(t,M0(i,j)*exp(-t/T2(i,j)),'s','MarkerFaceColor','r'); hold off
                legend('Signal','Fit')
                drawnow
%                 close all
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
print('-dpng','-r300','T2_weighted_SENSE')