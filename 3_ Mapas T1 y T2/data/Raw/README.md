# Experiencia 2: Mapas T1 y T2

## Simulación de imágenes de resonancia
Para la generación del fantoma dado en la experiencia, puede considerar el siguiente script:
```matlab
% Dominio de la imagen
Isz = [100 100];
[X, Y] = meshgrid(linspace(-1,1,Isz(2)),linspace(-1,1,Isz(1)));

% Centros de los cilindros
xc = [-0.5, 0.5; 0.5, 0.5; -0.5, -0.5; 0.5, -0.5];

% Crea el objeto con los cilindros
C = false([size(X), 4]);
for i=1:size(xc,1)
    C(:,:,i) = sqrt((X-xc(i,1)).^2 + (Y-xc(i,2)).^2) < 0.25;
end

% Valores T1 y T2 en cada cilindro
t1 = [1000 1500 850 500];
t2 = [200 300 50 20];
T1 = t1(1)*C(:,:,1) + t1(2)*C(:,:,2) + ...
     t1(3)*C(:,:,3) + t1(4)*C(:,:,4);
T2 = t2(1)*C(:,:,1) + t2(2)*C(:,:,2) + ...
     t2(3)*C(:,:,3) + t2(4)*C(:,:,4);
T1(~(sum(C,3))) = 1e+10;
T2(~(sum(C,3))) = 1e+10;

% Verificación
figure,
subplot 121
imagesc(T1,'AlphaData',sum(C,3)); caxis([min(t1) max(t1)])
subplot 122
imagesc(T2,'AlphaData',sum(C,3)); caxis([min(t2) max(t2)])
```


## Trabajando con los datos
### Formato y lectura de los datos
En la carpeta ```data/RAW/``` se encuentran los datos ```raw``` de 2 adquisiciones usando *Look-Locker* (LL) y 3 usando *Multi-Echo* (ME). Para leer y trabajar con el ```raw data``` puede utilizar la información entregada en la [experiencia anterior](https://github.com/hmella/IEE3773/blob/master/Experiencia%201:%20Reconstruccion/README.md). Adicionalmente, en la carpeta ```data/DICOM/``` se encuentran las recontrucciones hechas por el resonador de cada uno de los ```raw``` data, las que puede utilizar para sus reconstrucciones.

Una descripción de cada archivo ```raw``` contenido en ```data```, que incluye todos los parámetros necesarios para la estimación de los mapas T1 y T2 se muestra a continuación:
| Archivo | Secuencia | TR (msec) | TE (msec) | <img src="https://latex.codecogs.com/svg.latex?(\Delta&space;t,t_0)" title="(\Delta t,t_0)" /> (msec)| Flip angle (°) |
| --- | --- | --- | --- | --- | --- |
| ```raw_000``` | LL | 1000 | 3.336 | (66, 21) | 12 |
| ```raw_001``` | LL | 4000 | 3.336 | (213, 21) | 12 |
| ```raw_002``` | ME | 240 | 20 | - | - |
| ```raw_003``` | ME | 1500 | 20 | - | - |
| ```raw_004``` | ME | 1500 | 40 | - | - |

En el caso de las adquisiciones ME, el tiempo en el que se adquirió el eco <img src="https://latex.codecogs.com/svg.latex?i" title="i" /> está dado por <img src="https://latex.codecogs.com/svg.latex?t_i=i\times&space;TE" title="t_i=i\times TE" />. Para las adqusiciones LL, el tiempo en el que se adquirió la imagen <img src="https://latex.codecogs.com/svg.latex?j" title="j" /> está dado por <img src="https://latex.codecogs.com/svg.latex?t_j=t_0&space;&plus;&space;TE&space;&plus;&space;j\times\Delta&space;t" title="t_j=t_0 + TE + j\times\Delta t" />.

Las imágenes reconstruidas a partir del raw data, adquiridas con la segunda bobina y para cada tiempo de adquisición, se muestran en la figura de abajo.

![](https://github.com/hmella/IEE3773/blob/master/images/exp_2a.png?raw=true)

### Formato y lectura de las imágenes
Para leer las imágenes en formato ```DICOM``` puede utilizar las funciones ```dicomread``` y ```dicominfo```, las que entregan la imagen y la información de la adquisición, respectivamente. Adicionalmente, puede usar la función ```src/ReadPhilipsDICOM.m```, la que lee, escala y ordena las imágenes, entregando un objeto ```struct``` con los distintos tipos de imágenes contenidas en el ```DICOM```, además de su información.

El siguiente script permite leer las imágenes ```DICOM``` adquiridas usando una secuencia ME.
```matlab
% Lectura de un DICOM de la adquisición Look-Locker
metadata = ReadPhilipsDICOM('data/DICOM/IM_0002.dcm',{'MAGNITUDE','PHASE'});
info = metadata.DICOMInfo;  % información del DICOM
M = metadata.MAGNITUDE;     % imágenes de magnitud
P = metadata.PHASE;         % imágenes de fase
```
En caso de que no exista alguna de los campos solicitados a la función (```'MAGNITUDE'``` o ```'PHASE'```), el resultado será un arreglo vacío. Las imágenes contenidas en el arreglo ```M``` para cada tiempo de adquisición se muestran en la figura de abajo.

![](https://github.com/hmella/IEE3773/blob/master/images/exp_2b.png?raw=true)

## Algunos tips e informaciones para el desarrollo de la experiencia
* Para esta experiencia no existe una adquisición con la bobina de cuerpo completo, por lo que para la estimación de las sensibilidades de las bobinas deberá usar la reconstrucción de suma de cuadrados.
* Para programar el ajuste de los datos manualmente, considere utilizar [esta página](https://la.mathworks.com/matlabcentral/answers/281886-how-to-use-least-square-fit-in-matlab-to-find-coefficients-of-a-function) como referencia
* Para la estimación de los mapas T1 y T2, utilice sólo 1 ```raw data``` de la adquisición LL y 1 de ME (utilice aquellos que entreguen valores de T1 y T2 más cercanos a la literatura).
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

  <img src="https://github.com/hmella/IEE3773/blob/master/images/exp_2c.png?raw=true" width="400" height="400">

* En caso de que no pueda realizar las reconstrucciones a partir de los ```raw data```, puede utilizar las imágenes contenidas en la carpeta ```data/DICOM```. Sin embargo esta opción recibirá una penalización de 0.5 décimas en la nota final.
* Los modelos a utilizar para el ajuste de los datos son:
    <p style="text-align: center;">
    <img src="https://latex.codecogs.com/svg.latex?I&space;=&space;A\exp(-t/T1)&space;&plus;&space;B" title="I = A\exp(-t/T1) + B" />,
    </p>
    <p style="text-align: center;">
    <img src="https://latex.codecogs.com/svg.latex?I&space;=&space;A\exp(-t/T2)&space;&plus;&space;B" title="I = A\exp(-t/T2) + B" />,
    </p>
    donde los parámetros a estimar son <img src="https://latex.codecogs.com/svg.latex?A" title="A" />, <img src="https://latex.codecogs.com/svg.latex?B" title="B" />, T1 y T2.
* La estimación del mapa T1 usando LL entrega un valor de T1 que es un poco más corto que el valor original. Denotando como <img src="https://latex.codecogs.com/gif.latex?T1_{eff}" title="T1_{eff}" /> el valor más corto, no olvide corregir el mapa encontrado utilizando la siguiente expresión:
    <p style="text-align: center;">
    <img src="https://latex.codecogs.com/svg.latex?T1_{eff}=\frac{\tau}{(\tau/T1-\ln(\cos\alpha))}" title="T1_{eff}=\frac{\tau}{(\tau/T1-\ln(\cos\alpha))}" />
    </p>
  donde (nuevamente) <img src="https://latex.codecogs.com/gif.latex?T1_{eff}" title="T1_{eff}" /> es la estimación obtenida a través del ajuste polinomial, T1 el valor que se desea encontrar y <img src="https://latex.codecogs.com/gif.latex?\alpha" title="\alpha" /> el flip angle de la adquisición (ver tabla).
