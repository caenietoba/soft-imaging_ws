import g4p_controls.*;
import processing.video.*;

PImage img;
Movie video;

PGraphics pg_base;
PGraphics pg_modified;

int w = 120;
int size = 500;
int matrixsize = 3;

int type = 0;

// matrices to produce different effects. This is a high-pass 
// filter; it accentuates the edges. 
float[][] matrix = { { -1, -1, -1 },
                     { -1,  9, -1 },
                     { -1, -1, -1 } }; 
                     
float[][] matrix1 = { { 1, 1, 1 },
                     { 1,  1, 1 },
                     { 1, 1, 1 } }; 
                     
float[][] matrix2 = { { -1, 0, 1 },
                     { -1,  0, 1 },
                     { -1, 0, 1 } };

float[][] matrix_to_use;

int[] hist = new int[256];
int[] hist_sat = new int[256];
int[] hist_hue = new int[256];
int[] hist_green = new int[256];
int[] hist_red = new int[256];
int[] hist_blue = new int[256];
int[] hist_alpha = new int[256];

int otsu; //Umbral dado por el algoritmo de otsu

GButton imgButton, videoButton, grayButton, convolutionButton;
GCheckbox brigthHistogramCheck, redHistogramCheck, greenHistogramCheck, blueHistogramCheck;
GCheckbox hueHistogramCheck, alphaHistogramCheck, saturHistogramCheck;
GToggleGroup toggleGroup;
GOption grayCheck, convolutionCheck, segmentationCheck;


void setup() {
  size(1200, 700);
  
  matrix_to_use = matrix;
  
  img = loadImage("mandril.jpg");
  
  calculateHistograms();
  otsu = otsuAlgorithm();
  
  video = new Movie(this, "cat.mp4");
  video.loop();
  
  pg_base = createGraphics(500, 500);
  pg_modified = createGraphics(500, 500);
  
  toggleGroup = new GToggleGroup();
  grayCheck = new GOption(this, 300, 575, 100, 30, "Image");
  convolutionCheck = new GOption(this, 300, 600, 100, 30, "Image");
  segmentationCheck = new GOption(this, 300, 625, 100, 30, "Image");
  
  toggleGroup.addControl(grayCheck);
  toggleGroup.addControl(convolutionCheck);
  toggleGroup.addControl(segmentationCheck);
  
  imgButton = new GButton(this, 100, 575, 100, 30, "Image");
  imgButton.addEventHandler(this, "handleImageButton");
  videoButton = new GButton(this, 100, 620, 100, 30, "Video");
  videoButton.addEventHandler(this, "handleVideoButton");
  
  brigthHistogramCheck = new GCheckbox(this, 500, 525, 125, 25, "Brigthnes");
  redHistogramCheck = new GCheckbox(this, 500, 550, 125, 25, "Red");
  greenHistogramCheck = new GCheckbox(this, 500, 575, 125, 25, "Green");
  blueHistogramCheck = new GCheckbox(this, 500, 600, 125, 25, "Blue");
  saturHistogramCheck = new GCheckbox(this, 500, 625, 125, 25, "Saturation");
  hueHistogramCheck = new GCheckbox(this, 500, 650, 125, 25, "Hue");
  alphaHistogramCheck = new GCheckbox(this, 500, 675, 125, 25, "Alpha");
  
}

void draw() {
  
  background(0);
  
  img.resize(500,500);
  pg_base.beginDraw();
  if( type == 0)
    pg_base.image(img, 0, 0);
  else
    pg_base.image(video, 0, 0);
  pg_base.endDraw();
  pg_base.loadPixels();
  image(pg_base, 0, 0);
  
  
  pg_modified.beginDraw();
  pg_modified.loadPixels();
  copyPixels(pg_base, pg_modified);
  if(grayCheck.isSelected()){
    pg_modified.pixels = gray(pg_modified.pixels);
  }else if(convolutionCheck.isSelected()){
    pg_modified.pixels = convolution(pg_modified.pixels, matrix, matrixsize);
    areaConvolution();
  }else if(segmentationCheck.isSelected()){
    pg_modified.pixels = seg(otsu, pg_base.pixels);
  }
  pg_modified.endDraw();
  image(pg_modified, 500,0);
  
  calculateHistograms( pg_modified.pixels );
  
  pg_modified.beginDraw();
  pg_modified.stroke(255);
  if(brigthHistogramCheck.isSelected()){
    drawHistogram(hist, pg_modified, color(#FFFFFF));
  }else if(redHistogramCheck.isSelected()){
    drawHistogram(hist_red, pg_modified, color(247,82,107));
  }else if(greenHistogramCheck.isSelected()){
    drawHistogram(hist_green, pg_modified, color(38,209,65));
  } else if(blueHistogramCheck.isSelected()){
    drawHistogram(hist_blue, pg_modified, color(38,82,209));
  } else if(saturHistogramCheck.isSelected()){
    drawHistogram(hist_sat, pg_modified, color(#FFFFFF));
  } else if(hueHistogramCheck.isSelected()){
    drawHistogram(hist_hue, pg_modified, color(#FFFFFF));
  } else if(alphaHistogramCheck.isSelected()){
    drawHistogram(hist_alpha, pg_modified, color(#FFFFFF));
  }
  pg_modified.endDraw();
  image(pg_modified, 500,0);
  
  textSize(25);
  text("FPS: " + int(frameRate), 1050, 250); 

}

/*-------------------------------
----------Convolución------------
-------------------------------*/

//Función para calcular la convolución en el área alrededor del mouse
void areaConvolution(){
   // Calculate the small rectangle we will process
    int xstart = constrain(mouseX - w/2, 10, pg_base.width-10);
    int ystart = constrain(mouseY - w/2, 10, pg_base.height-10);
    int xend = constrain(mouseX + w/2, 10, pg_base.width-10);
    int yend = constrain(mouseY + w/2, 10, pg_base.height-10);
    loadPixels();
    // Begin our loop for every pixel in the smaller image
    for (int x = xstart; x < xend; x++) {
      for (int y = ystart; y < yend; y++ ) {
        color c = convolution(x, y, matrix, matrixsize, pg_base.pixels);
        int loc = x + (y)*(pg_base.width+100)*2;
        pixels[loc] = c;
        //int loc2 = x + 500 + (y)*pg_base.width*2;
        //pixels[loc2] = c;
      }
    }
  updatePixels();
}

//Arregla el array de pixeles para pasarlo a la función de convolución
color[] convolution(color[] pixelArray, float[][] matrix, int matrixsize){
  color [] result = new color[pixelArray.length];
  for(int i=0; i<pixelArray.length; i++){
    result[i] = convolution(i%size, i/size, matrix, matrixsize, pixelArray);
  }
  return result;
}

//Función de convolución
color convolution(int x, int y, float[][] matrix, int matrixsize,  color[] pixelArray) {
  float rtotal = 0.0;
  float gtotal = 0.0;
  float btotal = 0.0;
  int offset = matrixsize / 2;
  
  for (int i = 0; i < matrixsize; i++ ) {
    for (int j = 0; j < matrixsize; j++ ) {
      
      int xloc = x + i-offset;
      int yloc = y + j-offset;
      int loc = xloc + img.width*yloc;
      
      loc = constrain(loc,0,pixelArray.length-1);
      rtotal += (red(pixelArray[loc]) * matrix[i][j] );
      gtotal += (green(pixelArray[loc]) * matrix[i][j]);
      btotal += (blue(pixelArray[loc]) * matrix[i][j]);
    }
  }
  
  rtotal = constrain(rtotal, 0, 255);
  gtotal = constrain(gtotal, 0, 255);
  btotal = constrain(btotal, 0, 255);

  return color(rtotal, gtotal, btotal); 
}

/*------------------------------------
----------Escala de grises------------
------------------------------------*/

//Función que pasa a escala de grises con luma 240
color[] gray( color[] pixels_array ){
  for (int i = 0; i < pixels_array.length; i++) {
    color p = pixels_array[i]; // Guardamos el color del pixel
    float r = red(p); // Modificamos el valor del rojo
    float g = green(p); // Modificamos el valor del verde
    float b = blue(p); // Modificamos el valor del azul
    float luma240 = 0.212*r + 0.701*g + 0.087*b; //Método del Luma 240
    float promedyGray = (r + g + b) / 3.0; //Método del promedio
    pixels_array[i] = color(luma240); 
  }
  return pixels_array;
}

/*-------------------------------
----------Histogramas------------
-------------------------------*/

//Calcula el histograma de un arreglo de pixeles
void calculateHistograms( int[] pixels_array ){
  for (int i = 0; i < pixels_array.length; i++) {
    int bright = int(brightness(pixels_array[i]));
    hist[bright]++; 
    int saturation = int(saturation(pixels_array[i]));
    hist_sat[saturation]++; 
    int hue = int(hue(pixels_array[i]));
    hist_hue[hue]++; 
    int green = int(green(pixels_array[i]));
    hist_green[green]++; 
    int blue = int(blue(pixels_array[i]));
    hist_blue[blue]++; 
    int red = int(red(pixels_array[i]));
    hist_red[red]++;
    int alpha = int(red(pixels_array[i]));
    hist_alpha[alpha]++; 
  }
}

//Calcula el histograma de la imagen global
void calculateHistograms(){
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      int bright = int(brightness(img.get(i, j)));
      hist[bright]++;
    }
  }
}

//Dibuja el histograma en el pg pasado
void drawHistogram(int[] histo, PGraphics pg, color _color){
  int histMax = max(histo);
  pg.stroke( _color );
  // Draw half of the histogram (skip every second value)
  for (int i = 3; i < size; i += 2) {
    // Map i (from 0..img.width) to a location in the histogram (0..255)
    int which = int(map(i, 0, size, 0, 255));
    // Convert the histogram value to a location between 
    // the bottom and the top of the picture
    int y = int(map(histo[which], 0, histMax, size-10, 10));
    pg.line(i, pg.height-10, i, y);
  }
}

/*--------------------------------
----------Segmentación------------
--------------------------------*/

//Binariza el arreglo de pixeles según el umbral
color[] seg( int umbral, color[] pixels_array ){
  color[] new_array = new color[pixels_array.length];
  for (int i = 0; i < pixels_array.length; i++) {
    int bright = int(brightness(pixels_array[i]));
    if( bright < umbral ){
      new_array[i] = color(0);
    }else{
      new_array[i] = color(255);
    }
  }
  return new_array;
}


/*Algoritmos para hallar el umbral. El mejor es el de otsu
----------------------------------------------------------
*/

int calculateUmbralPromedy(){
  int umbral = 0;
  for( int i=2; i<256; i++ ){
    umbral += hist[i];
  }
  umbral = umbral / 256 ;
  return umbral;
}

int calculateUmbral2Tops(){
  int max_two = 0;
  int max_hist = max( hist );
  
  for(int i=3; i<256; i++){
    if( hist[i] > max_two && hist[i] != max_hist ){
      max_two = hist[i];
    }
  }
  
  return max_two;
}

// Get binary treshold using Otsu's method. Tomado de https://bostjan-cigan.com/java-image-binarization-using-otsus-algorithm/
int otsuAlgorithm() {
  int total = size*size;
 
  float sum = 0;
  for(int i=0; i<256; i++) 
    sum += i * hist[i];
 
  float sumB = 0;
  int wB = 0;
  int wF = 0;
 
  float varMax = 0;
  int threshold = 0;
 
  for(int i=0 ; i<256 ; i++) {
    wB += hist[i];
    if(wB == 0) continue;
    wF = total - wB;
 
    if(wF == 0) break;
 
    sumB += (float) (i * hist[i]);
    float mB = sumB / wB;
    float mF = (sum - sumB) / wF;
 
    float varBetween = (float) wB * (float) wF * (mB - mF) * (mB - mF);
 
    if(varBetween > varMax) {
      varMax = varBetween;
      threshold = i;
    }
  }
 
  return threshold;
 
}

/*-----------------------------------------------------*/

void copyPixels(PGraphics in, PGraphics out){
  for(int i=0; i<in.pixels.length; i++){
    out.pixels[i] = in.pixels[i];
  }
}

void movieEvent(Movie m) {
  m.read();
}

public void handleImageButton(GButton button, GEvent event){
  
  type = 0;
  
  brigthHistogramCheck.setVisible(true);
  redHistogramCheck.setVisible(true);
  greenHistogramCheck.setVisible(true);
  blueHistogramCheck.setVisible(true);
  hueHistogramCheck.setVisible(true);
  alphaHistogramCheck.setVisible(true);
  saturHistogramCheck.setVisible(true);
}

public void handleVideoButton(GButton button, GEvent event){
  
  type = 1;
  
  brigthHistogramCheck.setVisible(false);
  redHistogramCheck.setVisible(false);
  greenHistogramCheck.setVisible(false);
  blueHistogramCheck.setVisible(false);
  hueHistogramCheck.setVisible(false);
  alphaHistogramCheck.setVisible(false);
  saturHistogramCheck.setVisible(false);
}
