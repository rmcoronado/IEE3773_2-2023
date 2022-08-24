# Experiencia 1: Reconstrucción de Imágenes
## Trabajando con datos ```raw```
### Formato de los datos
[a link](https://github.com/user/repo/blob/branch/other_file.md)
El ```raw data``` es la información que el resonador mide directamente desde las bobinas y está formado por todas las adquisiciones que realizó el scanner para la formación de una imagen específica. Para una adquisición cartesiana, los factores que influyen en las dimensiones del ```raw data``` son el número de codificaciones de fase, la frecuencia de muestreo, el número de slices y el número de NSAs, entre otros.

Cada ```raw data``` está compuesto por 2 archivos con extensiones ```.list``` y ```.data```. El primero contiene un encabezado con datos sobre la adquisición (factor de sobremuestreo, número de ecos, número de slices, número de bobinas/canales, etc) e información para el formateo de los datos (mediciones) contenidas en el segundo archivo (un ejemplo de parte del contenido de un archivo ```.list``` se muestra en el link de abajo).

<details><summary><u>Ejemplo: encabezado del archivo .list </u></summary>
<p>

```bash
# === GENERAL INFORMATION ========================================================
#
# n.a. n.a. n.a.  number of ...                        value
# ---- ---- ----  ----------------------------------   -----
.    0    0    0  number_of_mixes                    :     1
#
# mix  n.a. n.a.  number of ...                        value
# ---- ---- ----  ----------------------------------   -----
.    0    0    0  number_of_encoding_dimensions      :     2
.    0    0    0  number_of_dynamic_scans            :     1
.    0    0    0  number_of_cardiac_phases           :     1
.    0    0    0  number_of_echoes                   :     1
.    0    0    0  number_of_locations                :     2
.    0    0    0  number_of_extra_attribute_1_values :     1
.    0    0    0  number_of_extra_attribute_2_values :     1
.    0    0    0  number_of_signal_averages          :     2
#
# n.a. n.a. loca  number of ...                        value
# ---- ---- ----  ----------------------------------   -----
.    0    0    0  number of coil channels            :     8
.    0    0    1  number of coil channels            :     8
# ---- ---- ----  ----------------------------------   -----
# For more channel information, see the trailer of this file.
#
# mix  echo n.a.  k-space coordinate ranges            start  end
# ---- ---- ----  ----------------------------------   -----  -----
.    0    0    0  kx_range                           :  -232    231
.    0    0    0  ky_range                           :  -115    114
#
# mix  echo n.a.  k-space oversample factors           value
# ---- ---- ----  ----------------------------------   ---------
.    0    0    0  kx_oversample_factor               :    2.0000
.    0    0    0  ky_oversample_factor               :    1.0000
#
# mix  n.a. n.a.  reconstruction matrix                value
# ---- ---- ----  ----------------------------------   -----
.    0    0    0  X-resolution                       :   256
.    0    0    0  Y-resolution                       :   256
#
# n.a. n.a. n.a.  SENSE factors (spatial dirs only!)   value
# ---- ---- ----  ----------------------------------   ---------
.    0    0    0  X-direction SENSE factor           :    1.0000
.    0    0    0  Y-direction SENSE factor           :    1.0000
#
# mix  echo loca  imaging space coordinate ranges      start  end
# ---- ---- ----  ----------------------------------   -----  -----
.    0    0    0  X_range                            :  -128    127
.    0    0    0  Y_range                            :  -256     -1
.    0    0    1  X_range                            :  -128    127
.    0    0    1  Y_range                            :  -256     -1
```
</p>
</details>

&nbsp;
Los ```raw data``` necesarios para la realización de esta experiencia se encuentran dentro de la carpeta ```data/``` y corresponden a una adquisición con múltiples bobinas (```raw_001.list``` y ```raw_001.data```) y otra con la bobina de cuerpo completo (```raw_002.list``` y ```raw_002.data```). 


### Lectura de los datos
Para cargar los datos en Matlab, deben usar la función ```src/readListData```, la que recibe como entrada el nombre del archivo raw (sin extensión), el nombre con extensión ```.list``` o el nombre con extensión ```.data``` (ver el ejemplo de más abajo). Como salida, la función entrega el espacio <img src="https://latex.codecogs.com/svg.latex?k" title="k" /> (transformada de Fourier del objeto) de todas las imágenes tomadas durante la adquisición.
```matlab
% carga los datos adquiridos con múltiples bobinas
K = readListData('data/raw_001');
```
Para los datos de esta experiencia, las dimensiones de ```K``` son <img src="https://latex.codecogs.com/gif.latex?464\times&space;230\times&space;2\times&space;2\times&space;8" title="464\times 230\times 2\times 2\times 8" />, las que representan el número de mediciones en la dirección de frecuencia (incluyendo el sobremuestreo), el número de codificaciones de fase, el número de slices, los NSAs y el número de bobinas (comparelos con los valores contenidos en el archivo ```raw_001.list```).


Corrigiendo el sobremuestreo de los espacios <img src="https://latex.codecogs.com/svg.latex?k" title="k" /> adquiridos por todas las bobinas y graficándolos se obtiene:
![](https://github.com/hmella/IEE3773_2-2020/blob/master/images/exp_1a.png?raw=true)


### Del espacio <img src="https://latex.codecogs.com/svg.latex?\large\boldsymbol{k}" title="k" /> al dominio de la imagen
Para pasar del espacio <img src="https://latex.codecogs.com/svg.latex?k" title="k" /> al dominio de la imagen se debe utilizar la transformada de Fourier inversa sobre ```K```. Lo anterior se puede hacer a través de las función ```src/ktoi```, las cual aplica la transformada de Fourier inversa utilizando el algoritmo FFT. De la misma manera, para pasar del dominio de la imagen al espacio k se puede utilizar la función ```src/itok```.

Ambas funciones internamente aplican todos los *shifts* necesarios para ordenar las frecuencias en el espacio de Fourier.

Para aplicar la función ```ktoi``` sobre ```K``` se se debe utilizar el siguiente comando:
```matlab
% aplica la transformada de Fourier inversa sobre K en las dimensiones [1 2]
I = ktoi(K, [1 2]);
```
donde el vector ```[1 2]``` indica que la operación se debe aplicar en dichas dimensiones. Esto es sumamente importante cuando el objeto de entrada posee más de 2 dimensiones. El comando anterior entrega como salida las siguientes imágenes:
![](https://github.com/hmella/IEE3773_2-2020/blob/master/images/exp_1b.png?raw=true)


## Algunos tips e informaciones para el desarrollo de la experiencia
* El archivo ```main.m``` contiene todos los ejemplos anteriormente mencionados (y más), y debería ser un buen punto de partida para desarrollar la experiencia.
* Dentro del mismo archivo hay un pequeño script que les permite obtener la máscara binaria del objeto para la estimación de las inhomogeneidades de campo según el artículo de [Pruessman et al. - 1999](https://github.com/hmella/IEE3773_2-2020/blob/master/Experiencia%201:%20Reconstruccion/bib/Pruessmann%20et%20al.%20-%201999%20-%20SENSE%20Sensitivity%20encoding%20for%20fast%20MRI.pdf).
* Para "extender" la máscara usando *Region Growing* pueden usar una convolución (ver archivo ```main.m```) o cualquier función de Matlab que estimen conveniente (no es necesario que lo implementen de cero).
* El ajuste polinomial propuesto por Pruessman et al. para crear un mapa de sensibilidad suave, se puede realizar utilizando cualquier función de Matlab (no es necesario que lo implementen ustedes). Pueden usar, por ejemplo, la funcion ```gridfit``` contenida en la carpeta ```src/gridfitdir/``` (ver ejemplo de abajo).
    ```matlab
    % estima las sensibilidades usando la función gridfit
    Sxy = I./Ib;
    for coil=1:Ncoils
        Sxy_i = Sxy(:,:,coil);
        S(:,:,coil) = mask_rg.*gridfit(X(mask),Y(mask),Sxy_i(mask),1:Isz(2),1:Isz(1));
    end
    ```
    Como las sensibilidades deben ser suaves, pruebe cambiando las opciones ```interp```, ```regularizer``` y ```smoothness``` de la función ```gridfit``` (mire la implementación y documentación de la función).
* Si no obtiene los resultados adecuados con ```gridfit```, puede generar las sensibilidades suavizando la variable ```Sxy``` usando un filtro pasa-bajos. Para esto puede usar la función ```src/ButterworthFilter.m``` de la siguiente manera:
    ```matlab
    % crea un filtro pasabajos
    H = ButterworthFilter(Isz,Isz/2,7,10); % para obtener más o menos suavizado 
                                           % prueben cambiando los dos últimos 
                                           % números
    S = ktoi(H.*itok(Sxy, [1 2]), [1 2])
    ```
