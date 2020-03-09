import processing.sound.*;
import processing.video.*;
import gab.opencv.*;

float minBlobArea = 200;     // reject blobs smaller than this
ArrayList<Contour> blobs;    // list of blob contours
OpenCV cv;                   // instance of the OpenCV library

Movie mov;
Movie mov2;

float x;
float y;

SinOsc[] sineWaves; // Array of sines
float[] sineFreq; // Array of frequencies
int numSines = 15; // Number of oscillators to use



void setup() {  
  size(1280, 720);
  //background(255);
  //background(0);

  mov = new Movie(this, "lava.mov");

  // Pausing the video at the first frame. 
  mov.play();
  mov.jump(0);
  mov.loop();

  cv = new OpenCV(this, mov.width, mov.height);

  cv.invert();
  cv.threshold(70);     // threshold leaves just the lightest area 
  cv.dilate();          // fill holes and smooth edges
  cv.erode();           // separate connected components


  sineWaves = new SinOsc[numSines]; // Initialize the oscillators
  sineFreq = new float[numSines]; // Initialize array for Frequencies

  for (int i = 0; i < numSines; i++) {
    // Calculate the amplitude for each oscillator
    float sineVolume = (1.0 / numSines) / (i + 1);
    // Create the oscillators
    sineWaves[i] = new SinOsc(this);
    // Start Oscillators
    sineWaves[i].play();
    // Set the amplitudes for all oscillators
    sineWaves[i].amp(sineVolume);
  }
}

void draw() {
  //
  if (mov.available()) {
    mov.read();
    image(mov, 0, 0);

    cv = new OpenCV(this, get(0, 0, width, height));

    // after this, you can do the preprocessing, blob
    // tracking, etc like in the examples
    cv.threshold(150);
    image(cv.getOutput(), 0, 0);
  }

  ArrayList<Contour> blobs = cv.findContours();
 
  // iterate through all the blobs
  for (Contour blob : blobs) {
    
    float minArea = 50;
    //float maxArea = 1280;
    //blob.area() > maxArea
    
    if (blob.area() < minArea) {
      continue;
    }

    // find their contour, which is an ArrayList of points
    // try the getConvexHull() command instead – notice the difference?
    ArrayList<PVector> pts = blob.getPolygonApproximation().getPoints();
    //ArrayList<PVector> pts = blob.getConvexHull().getPoints();

    // values for calculating the centroid
    float centerX = 0;
    float centerY = 0;

    // draw the blob and add up all the x/y points
    noFill();
    stroke(255, 150, 0);
    strokeWeight(3);
    beginShape();
    for (PVector pt : pts) {
      vertex(pt.x, pt.y);
      centerX += pt.x;
      centerY += pt.y;
    }
    endShape(CLOSE);

    // average the points and draw the centroid
    centerX /= pts.size();
    centerY /= pts.size();
    fill(0, 150, 255);
    noStroke();
    ellipse(centerX, centerY, 10, 10);
    
    println(centerX);
    println(centerY);

    float yoffset = map(centerY, 0, height, 0, 1);
    //Map mouseY logarithmically to 150 - 1150 to create a base frequency range
    float frequency = pow(1000, yoffset) + 150;
    //Use mouseX mapped from -0.5 to 0.5 as a detune argument
    float detune = map(centerX, 0, width, -0.5, 0.5);

    for (int i = 0; i < numSines; i++) { 
      sineFreq[i] = frequency * (i + 1 * detune);
      // Set the frequencies for all oscillators
      sineWaves[i].freq(sineFreq[i]);
    }
  }
}
