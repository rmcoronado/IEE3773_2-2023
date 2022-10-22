# Experiencia 5: Imágenes cardiacas

## Imágenes disponibles
Para esta experiencia se encuentran disponibles dos sets de datos DICOM adquiridos utilizando las instrucciones de la tarea.

Para leer los datos utilice:
```matlab
% Lee imagen de magnitud
metadata = ReadPhilipsDICOM('data/1/DICOM/IM_0012',{'MAGNITUDE'});
M = metadata.MAGNITUDE;          % imagen de magnitud
```

<img src="https://github.com/rmcoronado/IEE3773_2-2022/blob/main/5_%20imagenes%20cardiacas/Exp_5a_cardio.png" width="500" height="500">



## Trabajando con las imágenes
La única información necesaria para el desarrollo de la experiencia es el tamaño del pixel de cada imagen, el que se obtiene de la siguiente forma:
```matlab
% Tamaño del pixel [mm]
pxsz = metadata.DICOMInfo.PerFrameFunctionalGroupsSequence.Item_1.Private_2005_140f.Item_1.PixelSpacing; 
```
En caso de necesitar el tiempo en que fue adquirida cada imagen (para conocer en qué parte del ciclo cardiaco se encuentran), puede obtener dicha información de la siguiente manera:
```matlab
% Tiempos de adquisición de cada frame
Nfr = size(M,3);    % Nro. de frames
t = zeros([1 Nfr]); % tiempos de adquisición (ms)
for i=1:Nfr
    item = sprintf('Item_%d',i);
    t(i) = metadata.DICOMInfo.PerFrameFunctionalGroupsSequence.(item).CardiacSynchronizationSequence.Item_1.NominalCardiacTriggerDelayTime;
end
```



## Algunos tips e informaciones para el desarrollo de la experiencia
* Para estimar el SNR y comparar los contrastes entre imágenes debe dibujar una región de interés. Para lo anterior, puede utilizar lo siguiente:
```matlab
% Dibuja un ROI en la imagen y estima el valor promedio de los pixeles en su interior
figure,
imagesc(M(:,:,1))
h = imellipse(gca);

% Crea la máscara y estima el promedio
roi = h.createMask;
M1 = M(:,:,1);
mean(M1(roi))
```
