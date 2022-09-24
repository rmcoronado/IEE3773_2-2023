clear; clc; close all

% Agrega funciones en src/ al path de matlab
addpath(genpath('src/'))

%% Imágenes Look-Locker
% Selecciona la imagen que se va a utilizar
caso = 2;

% Lee raw data de una secuencia Look-Locker
if caso==1
    K = squeeze(readListData('data/RAW/raw_000.list'));
else
    K = squeeze(readListData('data/RAW/raw_001.list'));
end    
K = K(1:2:end,:,:,:);   % corrige sobremuestreo

% Rellena con zeros para alcanzar las mismas dimensiones
K = padarray(K,[0 3 0 0],0,'both');
K(:,160,:,:) = 0;

% Tamaño de la imagen, cantidad de bobinas y frames
Isz = size(K,[1 2]);
Nfr = size(K,3);
Ncoils = size(K,4);

% Del espacio K a la imagen (versión ruidosa)
I_noisy = ktoi(K, [1 2]);

%%
% Remueve las altas frecuencias del espacio K y reconstruye una imagen
% suavizada
Wr = WindowFilter(Isz(1), 0.4, 0.0, 'Tukey');      % filtro en dimension de lectura
Wc = WindowFilter(Isz(2), 0.4, 0.0, 'Tukey');      % filtro en dimension de fase
I = ktoi((Wr.weights'*Wc.weights).*K, [1 2]);      % múltiples bobinas

figure(1)
tiledlayout(1,3,'Padding','compact','TileSpacing','compact')
nexttile
imagesc(abs(I_noisy(:,:,8,1))); axis off; colormap gray,
nexttile
imagesc(abs(I(:,:,8,1))); axis off; colormap gray
nexttile
imagesc(Wr.weights'*Wc.weights)
axis off


%% SENSE
% Como la imagen adquirida con la bobina de cuerpo completo es muy ruidosa,
% la máscara del cerebro la obtendremos con las adquisiciones de cada
% bobina
mask = false(size(I,[1 2]));
for fr=1:1%Nfr
    for coil=1:Ncoils
        tmp = I(:,:,fr,coil);
        mask = or(mask, abs(tmp) > 0.15*max(abs(tmp(:))));
%         figure(2),
%         subplot 121
%         imagesc(mask)
%         subplot 122
%         imagesc(abs(tmp))        
%         drawnow
%         pause
    end
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

figure(3)
subplot 121
imagesc(mask)
subplot 122
imagesc(mask_rg)

% Estima las sensibilidades usando la función gridfit
fr = 1;
Isqr = squeeze(sqrt(sum(abs(I(:,:,:,:)).^2, 4)));
[X,Y] = meshgrid(1:Isz(2),1:Isz(1));
Sxy = squeeze(abs(I(:,:,fr,:)))./Isqr(:,:,fr);
S = zeros(size(Sxy));
for coil=1:Ncoils
    Sxy_i = Sxy(:,:,coil);
    S(:,:,coil) = mask_rg.*gridfit(X(mask),Y(mask),Sxy_i(mask),...
                    1:Isz(2),1:Isz(1),'interp','bilinear',...
                    'regularizer','springs','smoothness',50);
end


% Muestra sensibilidades estimadas
figure(4)
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
x0 = Isqr(:,:,1);%zeros(size(I,[1 2]));%Isqr;

% Parámetros de la optimización
max_i  = 300;
tol    = 1e-20;
show = false;

for fr = 1:size(I,3)
    % Construcción de B
    B = itok(squeeze(I(:,:,fr,:)),[1 2]);

    % Estimación usando CG
    [Isense_cg, history_cg] = opt_gradient(1,S,B,x0,max_i,tol,'cg',show,mask);
    
    I_sense(:,:,fr) = Isense_cg;
    
    figure(5)
    tiledlayout(1,2,'Padding','compact','TileSpacing','compact')    
    nexttile
    imagesc(abs(Isense_cg))
    nexttile
    semilogy(history_cg)
end

figure(6)
tiledlayout(3,5,'Padding','compact','TileSpacing','compact')
for fr=1:size(I,3)
    nexttile
    imagesc(abs(I_sense(:,:,fr))); axis off
end


%% MAPA T1
% Imagen para el ajuste de los datos
M = abs(I_sense);

% Tiempos de eco
TE = 3.336;
if caso==1
    t0 = 21;
    dt = 66;
else
    t0 = 21;
    dt = 213;
end
t = (t0+TE:dt:dt*size(M,3))';

% Disminuir el tamaño de la imagen
resize=false;
Isz_r = [32 32];
if resize
    Mr = zeros([Isz_r Nfr]);
    for i=1:Nfr
        Mr(:,:,i) = imresize(M(:,:,i),Isz_r);
    end
    mask = imresize(mask,Isz_r);
else
    Mr = M;
end

% Tamaño de la imagen
Isz = size(Mr);

% Parámetros del modelo
fo = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[-2000,-2000,0],...
               'Upper',[2000,2000,4000],...
               'StartPoint',[1600 1600 1000]);
g = fittype('a-2*b*exp(-x/c)','options',fo);

% Estima los valores de T1
T1 = NaN(Isz(1:2));
M0 = NaN(Isz(1:2));
flag = false;
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
            
            if false
                figure(8)
                subplot 121
                plot(t,M_,'b','LineWidth',2); hold on
                plot(t,f0.a - 2*f0.b*exp(-t/T1(i,j)),'s','MarkerFaceColor','r'); hold off
                legend('Signal','Fit')
                subplot 122
                imagesc(T1);colorbar; caxis([0 1000])
                drawnow
            end
            
            flag = 1;
            
        end
    end

    if true && flag
        figure(9)
        imagesc(T1);colorbar; caxis([0 1000])
        drawnow
    end  
    flag = 0;
    
end

figure(10)
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
    print('-dpng','-r300','T1_short_TR_SENSE')
else
    print('-dpng','-r300','T1_long_TR_SENSE')
end