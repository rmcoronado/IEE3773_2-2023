# Experiencia 3: Separación de agua y grasa

## Imágenes disponibles
Para esta experiencia se encuentra disponible un set de datos con distintas adquisiciones *Multi-Echo* que les permitirán cuantificar la fracción de agua y grasa en el hígado. Los datos fueron adquiridos con la misma secuencia de adquisición, pero variando la opción ```flyback``` del escáner, la cual controla en cómo se mide cada línea del espacio k (ver imagen de abajo). Lo anterior se debe a que se ha demostrado que la cuantificación de agua y grasa es muy sensible a cambios en la lectura del espacio k.
<img src="https://github.com/rmcoronado/IEE3773_2-2022/blob/main/4_%20Separacion%20de%20agua%20y%20grasa/image.png" width="550" height="225">

La estructura de los datos es la siguiente:
```bash
├── data/
│   ├── flyback_no/
│   │   ├── DIXON_2P/
│   │   ├── IDEAL/
│   ├── flyback_yes/
│   │   ├── DIXON_2P/
│   │   ├── DIXON_3P_IOI/
│   │   ├── DIXON_3P_OIO/
│   │   ├── IDEAL/
```
En su interior, cada carpeta contiene dos carpetas adicionales con la imagen en formato DICOM y RAW. Las carpetas con sufijo ```IOI``` y ```OIO``` se refieren a (*inphase, out-phase, in-phase*) y (*out-phase*, *in-phase*, *out-phase*), lo que significa que los tiempos de eco de la adquisición se escogieron de manera de que en el primero el peak de agua y grasa se encontráran en fase (fuera de fase), en el segundo fuera de fase (en fase) y el tercero en fase (fuera de fase).

## Trabajando con los datos
### Formato y lectura de los datos
Cada imagen fue adquirida usando una adquisición *Multi-Echo* (ME). Para leer y trabajar con el ```raw data``` puede utilizar la información entregada en la [primera experiencia]|. Adicionalmente, en las carpetas ```*/DICOM/``` se encuentran las recontrucciones hechas por el resonador de cada uno de los ```raw``` data, las que puede utilizar para sus estimaciones de fracción de agua y grasa.

Una descripción de cada imagen contenida en ```data/```, que incluye todos los parámetros necesarios para la estimación de la fracción de agua y grasa se muestra a continuación:
| Adquisición | <img src="https://latex.codecogs.com/gif.latex?(TE,\Delta&space;TE)" title="(TE,\Delta TE)" /> (msec) |
| --- | --- |
|```flyback_yes/DIXON_2P/```| (2.3030, 2.3030) |
|```flyback_yes/DIXON_3P_IOI/```| (4.6050, 2.3000) |
|```flyback_yes/DIXON_3P_OIO/```| (2.3030, 2.3000) |
|```flyback_yes/IDEAL/```| (1.1790, 1.8350) |
|```flyback_no/DIXON_2P/```| (2.3030, 2.3030) |
|```flyback_no/IDEAL/```| (1.1790, 1.8350) |


El tiempo en el que se adquirió el eco <img src="https://latex.codecogs.com/svg.latex?i" title="i" /> está dado por <img src="https://latex.codecogs.com/svg.latex?t_i=i\times&space;TE" title="t_i=i\times TE" />.

### Formato y lectura de las imágenes
Para leer las imágenes en formato ```DICOM``` puede utilizar las funciones ```dicomread``` y ```dicominfo```, las que entregan la imagen y la información de la adquisición, respectivamente. Adicionalmente, puede usar la función ```src/ReadPhilipsDICOM.m```, la que lee, escala y ordena las imágenes, entregando un objeto ```struct``` con los distintos tipos de imágenes contenidas en el ```DICOM```, además de su información.

El siguiente script permite leer las imágenes ```DICOM``` para la adquisición de Dixon de 2 puntos (```flyback=yes```).
```matlab
% Lectura de un DICOM de la adquisición Dixon de 2 puntos con flyback=yes
types = {'MAGNITUDE','REAL','IMAGINARY'};
metadata = ReadPhilipsDICOM('data/flyback_yes/DIXON_2P/DICOM/IM_000.dcm',types);
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
R = metadata.REAL;          % imágenes de la parte real
I = metadata.IMAGINARY;     % imágenes de la parte imaginaria

% Reconstruye imagen compleja para obtener la fase
I = metadata.REAL + 1j*metadata.IMAGINARY;
P = angle(I);
```
Las imágenes de fase ```P``` obtenidas a partir de la imagen compleja para los dos tiempos de eco se muestran en la figura de abajo.

![](https://github.com/rmcoronado/IEE3773_2-2022/blob/main/4_%20Separacion%20de%20agua%20y%20grasa/imagen3.png)

## Algunos tips e informaciones para el desarrollo de la experiencia
* Para esta experiencia no existe una adquisición con la bobina de cuerpo completo, por lo que para la estimación de las sensibilidades de las bobinas deberá usar la reconstrucción de suma de cuadrados.
* En caso de que las imágenes obtenidas a partir del ```raw data``` sean muy ruidosas, puede utilizar la función ```src/WindowFilter.m``` para construir un filtro y remover parte del ruido (con el costo de suavizar las imágenes).
  El siguiente ejemplo muestra como aplicar el filtro sobre el espacio K. 
  ```matlab
  % Remueve las altas frecuencias del espacio K y reconstruye una imagen
  % suavizada
  width = 0.6;
  lift  = 0.0;
  Wr = WindowFilter(Isz(1), width, lift, 'Tukey');      % filtro en dimension de lectura
  Wc = WindowFilter(Isz(2), width, lift, 'Tukey');      % filtro en dimension de fase
  I = ktoi((Wr.weights'*Wc.weights).*K, [1 2]);    % imagen filtrada
  ``` 
  En el script anterior la variable ```width``` representa el ancho del filtro (```width = 0.6``` significa que el filtro, en el espacio K, valdrá 1 en un ancho igual al 60% del tamaño de la imagen), mientras que ```lift``` es la cantidad de señal que permanecerá en el borde (con ```lift = 20``` la señal decaerá a un 20% de su valor en el borde).  Un ejemplo del filtro obtenido con el script anterior se presenta en la siguiente imagen.

  <img src="https://github.com/rmcoronado/IEE3773_2-2022/blob/main/4_%20Separacion%20de%20agua%20y%20grasa/imagen3.png" width="400" height="400">

* En caso de que no pueda realizar las reconstrucciones a partir de los ```raw data```, puede utilizar las imágenes contenidas en la carpeta ```data/DICOM```. Sin embargo esta opción recibirá una penalización de 0.5 décimas en la nota final.
* En caso de que necesite corregir los artefactos de wrapping en las imágenes de fase, en la carpeta ```src/``` se encuentran algunas funciones para hacerlo. Un ejemplo de cómo aplicarlas a las imágenes es el siguiente:
```matlab
% Corrije los artefactos de fase en ambos ecos
P(:,:,1) = unwrap2(P(:,:,1),'Mask',true(size(P(:,:,2))),'PixelSize',[1 1],...
                   'Seed','auto');
P(:,:,2) = unwrap2(P(:,:,2),'Mask',true(size(P(:,:,1))),'PixelSize',[1 1],...
                   'Seed','auto');
```
Los resultados obtenidos se muestran en la siguiente imagen:
<img src="https://github.com/rmcoronado/IEE3773_2-2022/blob/main/4_%20Separacion%20de%20agua%20y%20grasa/image4.png" width="991" height="439">

* En la carpeta ```src/``` se incluyó la función ```opt_gradient.m```, la que le permitirá combinar las bobinas usando SENSE y los métodos de gradiente descendente y conjugado.
* Para comparar la fracción de agua y grasa en el hígado, considere usar la función [imellipse](https://la.mathworks.com/help/images/ref/imellipse.html) de Matlab. El siguiente script es un ejemplo de su utilización:
  ```matlab
  % Dibuja un ROI en la imagen y estima el valor promedio de los pixeles en su interior
  figure,
  imagesc(P(:,:,1))
  h = imellipse(gca);

  % Crea la máscara y estima el promedio
  roi = h.createMask;
  P1 = P(:,:,1);
  mean(P1(roi))
  ```
