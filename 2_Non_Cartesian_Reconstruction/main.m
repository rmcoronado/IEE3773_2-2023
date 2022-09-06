clc, clear all, close all
%% CARGA DE RAW DATA RADIAL
Mk = load('C:\Users\ronal\Desktop\Laboratorio MR\2_Non_Cartesian_Reconstruction\data\radial\raw_000__data.mat');
Mk = Mk.Mk2;
Mk = permute(0.5*squeeze(double(Mk(:,1,:,:)+Mk(:,2,:,:))),[3 2 1]);  %[Ntr,Nk,Nc]
Mk_radial = Mk(:,:,:);

% Creación de la trayectoria radial
Nx = value; % spatial resolution
Nxr = value;
Nr = value;
kr = 0.5*  (-1+1/Nxr:1/Nxr:1).';
angle = 360/(Nr-1);
phi = (0:Nr-1)*angle + 180;
k_radial = kr * (cosd(phi) +1j*sind(phi));
w = (abs(k_radial));
figure, plot(k_radial)

%% Spiral Data

Mk = load('C:\Users\ronal\Desktop\Laboratorio MR\2_Non_Cartesian_Reconstruction\data\spiral\raw_000__data.mat');
Mk = Mk.Mk2;
Mk = permute(0.5*squeeze(double(Mk(:,1,:,:)+Mk(:,2,:,:))),[3 2 1]);  %[Ntr,Nk,Nc]
Mk_radial = Mk(:,:,:);

%Load spiral trayectory
k_spi = load('C:\Users\ronal\Desktop\Laboratorio MR\2_Non_Cartesian_Reconstruction\data\spiral\SpFinalCordsa.mat');
k_spi = k_spi.k_sp;
k_spi = k_spi(:,:,1) + 1j*k_spi(:,:,2);

figure, plot(k_spi)



