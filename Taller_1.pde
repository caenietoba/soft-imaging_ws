import processing.video.*;

PImage img;
Movie video;

PGraphics pg_base;
PGraphics pg_modified;

PFont mifont;

int w = 120;
int size = 500;
int matrixsize = 3;

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

//Botones
//------------------------------//
boolean img_button = true;
boolean video_button = false;
boolean gray_scale_btn = false;
boolean convolution_btn = false;
boolean segmentation_btn = false;
boolean brigth_histo = false;
boolean red_histo = false;
boolean green_histo = false;
boolean blue_histo = false;
boolean hue_histo = false;
boolean alpha_histo = false;
boolean satur_histo = false;

//En caso de que este activo la opción de video las opciones de los histogramas
//se desactivan
boolean active_histo_btns = true;  
//------------------------------//

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
  
  mifont = loadFont("Monospaced.bolditalic-38.vlw");
  textFont(mifont, 11);
}

void setStroke( boolean btn ){
  if( btn ){
    stroke(255);
    strokeWeight(2);
  }
  else{
    stroke(0);
    strokeWeight(0);
  }
}

void draw() {
  
  background(0);
  
  //------------------------------//
  //Botones 
  fill(#CD5C5C);
  setStroke( img_button );
  rect(100, 575, 100, 30, 7);
  setStroke( video_button );
  rect(100, 620, 100, 30, 7);
  setStroke( gray_scale_btn );
  rect(300, 575, 200, 20, 7);
  setStroke( convolution_btn );
  rect(300, 600, 200, 20, 7);
  setStroke( segmentation_btn );
  rect(300, 625, 200, 20, 7);
  if( active_histo_btns ){
    setStroke( brigth_histo );
    rect(600, 525, 170, 22, 7);
    setStroke( red_histo );
    rect(600, 550, 170, 22, 7);
    setStroke( green_histo );
    rect(600, 575, 170, 22, 7);
    setStroke( blue_histo );
    rect(600, 600, 170, 22, 7);
    setStroke( hue_histo );
    rect(600, 625, 170, 22, 7);
    setStroke( alpha_histo );
    rect(600, 650, 170, 22, 7);
    setStroke( satur_histo );
    rect(600, 675, 170, 22, 7);
  }
  
  fill(255);
  text("Image", 105, 602);
  text("Video", 105, 647);
  text("Gray scale", 305, 592);
  text("Convolution", 305, 617);
  text("Segmentation", 305, 642);
  if( active_histo_btns ){
    text("Brigthnes", 605, 547);
    text("Red", 605, 572);
    text("Green", 605, 597);
    text("Blue", 605, 622);
    text("Saturation", 605, 647);
    text("Hue", 605, 672);
    text("Alpha", 605, 697);
  }
  //------------------------------//
  
  img.resize(500,500);
  pg_base.beginDraw();
  if( img_button )
    pg_base.image(img, 0, 0);
  else
    pg_base.image(video, 0, 0);
  pg_base.endDraw();
  image(pg_base, 0, 0);
  
  pg_modified.beginDraw();
  pg_modified.loadPixels();
  copyPixels(pg_base, pg_modified);
  if(gray_scale_btn){
    pg_modified.pixels = gray(pg_modified.pixels);
  }else if(convolution_btn){
    pg_modified.pixels = convolution(pg_modified.pixels, matrix, matrixsize);
    areaConvolution();
  }else if(segmentation_btn){
    pg_modified.pixels = seg(otsu, pg_base.pixels);
  }
  pg_modified.updatePixels();  
  pg_modified.endDraw();
  image(pg_modified, 500,0);
  
  calculateHistograms( pg_modified.pixels );
  
  pg_modified.beginDraw();
  pg_modified.stroke(255);
  if(brigth_histo && active_histo_btns){
    drawHistogram(hist, pg_modified, color(#FFFFFF));
  }
  if(red_histo && active_histo_btns){
    drawHistogram(hist_red, pg_modified, color(247,82,107));
  }
  if(green_histo && active_histo_btns){
    drawHistogram(hist_green, pg_modified, color(38,209,65));
  }
  if(blue_histo && active_histo_btns){
    drawHistogram(hist_blue, pg_modified, color(38,82,209));
  }
  if(satur_histo && active_histo_btns){
    drawHistogram(hist_sat, pg_modified, color(#FFFFFF));
  }
  if(hue_histo && active_histo_btns){
    drawHistogram(hist_hue, pg_modified, color(#FFFFFF));
  }
  if(alpha_histo && active_histo_btns){
    drawHistogram(hist_alpha, pg_modified, color(#FFFFFF));
  }
  pg_modified.endDraw();
  image(pg_modified, 500,0);
  
  fill(255);
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

//Action handler de los botones
void mousePressed(){
  if( mouseX > 100 && mouseX < 200 && mouseY > 575 && mouseY < 605  ){
    img_button = true;
    video_button = false;
    active_histo_btns = true;
  }
  if( mouseX > 100 && mouseX < 200 && mouseY > 620 && mouseY < 650  ){
    img_button = false;
    video_button = true;
    active_histo_btns = false;
  }
  if( mouseX > 300 && mouseX < 500 && mouseY > 575 && mouseY < 595  ){
    gray_scale_btn = true;
    convolution_btn = false;
    segmentation_btn = false;
  }
  if( mouseX > 300 && mouseX < 500 && mouseY > 600 && mouseY < 620  ){
    gray_scale_btn = false;
    convolution_btn = true;
    segmentation_btn = false;
  }
  if( mouseX > 300 && mouseX < 500 && mouseY > 625 && mouseY < 645  ){
    gray_scale_btn = false;
    convolution_btn = false;
    segmentation_btn = true;
  }
  if( mouseX > 600 && mouseX < 770 && mouseY > 525 && mouseY < 545  ){
    brigth_histo = !brigth_histo;
  }
  if( mouseX > 600 && mouseX < 770 && mouseY > 550 && mouseY < 570  ){
    red_histo = !red_histo;    
  }
  if( mouseX > 600 && mouseX < 770 && mouseY > 575 && mouseY < 595  ){
    green_histo = !green_histo;   
  }
  if( mouseX > 600 && mouseX < 770 && mouseY > 600 && mouseY < 620  ){
    blue_histo = !blue_histo;   
  }
  if( mouseX > 600 && mouseX < 770 && mouseY > 625 && mouseY < 645  ){
    hue_histo = !hue_histo;   
  }
  if( mouseX > 600 && mouseX < 770 && mouseY > 650 && mouseY < 670  ){
    alpha_histo = !alpha_histo;   
  }
  if( mouseX > 600 && mouseX < 770 && mouseY > 675 && mouseY < 695  ){
    satur_histo = !satur_histo;   
  }
}
