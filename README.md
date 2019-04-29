# Taller de análisis de imágenes por software

## Propósito

Introducir el análisis de imágenes/video en el lenguaje de [Processing](https://processing.org/).

## Tareas

Implementar las siguientes operaciones de análisis para imágenes/video:

* Conversión a escala de grises.
* Aplicación de algunas [máscaras de convolución](https://en.wikipedia.org/wiki/Kernel_(image_processing)).
* (solo para imágenes) Despliegue del histograma.
* (solo para imágenes) Segmentación de la imagen a partir del histograma.
* (solo para video) Medición de la [eficiencia computacional](https://processing.org/reference/frameRate.html) para las operaciones realizadas.

Emplear dos [canvas](https://processing.org/reference/PGraphics.html), uno para desplegar la imagen/video original y el otro para el resultado del análisis.

## Integrantes

Complete la tabla:

| Integrante                   | github nick |
|------------------------------|-------------|
| Camilo Esteban Nieto Barrera | caenietoba  |

Descripción:

Se realizo un solo programa para todo el taller. 
En este se recoge una imagen y un video que son cargados junto con dos canvas.
Se alterna el video y la imagen con dos botones. 
Al video y a la imagen se les puede aplicar varios tipos de procesamiento, los que fueron programados son: cambio a escala de grises; convolución dada una matriz 3x3; segmentación a partir del histograma.
Para las imagenes es posible ver los distintos histogramas: intensidad, azul, rojo, verde, saturación, hue y alpha.
Para los videos se puede ver los fps.
