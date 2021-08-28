/**
 SpiralfromImage
 Copyright Jan Krummrey 2016
 
 Idea taken from Norwegian Creations Drawbot
 http://www.norwegiancreations.com/2012/04/drawing-machine-part-2/
 
 The sketch takes an image and turns it into a modulated spiral.
 Dark parts of the image have larger amplitudes.
 The result is being writen to a PDF for refinement in Illustrator/Inkscape
 
 Version 1.0 Buggy PDF export
 1.1 added SVG export and flag to swith off PDF export
 1.2 removed PDF export
     added and reworked CP5 gui (taken from max_bol's fork)
     fixed wrong SVG header
     
 Todo:
 - Choose centerpoint with mouse or numeric input
 - preview of spiral and amplitude changes in gui
 - remove clear display ( you either reload an image or quit? )
 
 SpiralfromImage is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with SpiralfromImage.  If not, see <http://www.gnu.org/licenses/>.
 
 jan@krummrey.de
 http://jan.krummrey.de
 */

import controlP5.*;                        // CP5 for gui
import java.io.File;                       // For file import and export

ControlP5 cp5;
File file;

Textarea feedbackText;
String locImg = "";                        // Source image absolute location
PImage sourceImg;                          // Source image for svg conversion
PImage displayImg;                         // Image to use as display
color c;                                   // Sampled color
float b;                                   // Sampled brightness
float dist = 5;                            // Distance between rings
float radius = dist/2;                     // Current radius
float aradius;                             // Radius with brighness applied up
float bradius;                             // Radius with brighness applied down
float alpha = 0;                           // Initial rotation
float density = 75;                        // Density
int counter=0;                             // Counts the samples
float ampScale = 2.4;                      // Controls the amplitude
float x, y, xa, ya, xb, yb;                // current X and y + jittered x and y 
float k;                                   // current radius
float endRadius;                           // Largest value the spiral needs to cover the image
color mask = color (255, 255, 255);        // This color will not be drawn (WHITE)
PShape outputSVG;                          // SVG shape to draw
String outputSVGName;                      // Filename of the generated SVG
String imageName;                          // Filename of the loaded image


void setup() {
  size(1024, 800);
  background(235); 
  noStroke();
  fill(245);
  rect(25, 25, 125, 750);
  fill(245);
  rect(175, 25, 537, 750);

  cp5 = new ControlP5(this);

  // create a new button with name 'Open'
  cp5.addButton("Open")
    .setLabel("Open File")
    .setBroadcast(false)
    .setValue(0)
    .setPosition(37, 37)
    .setSize(100, 19)
    .setBroadcast(true)
    ;
  // create a new button with name 'Draw'
  cp5.addButton("Draw")
    .setLabel("Generate SVG")
    .setBroadcast(false)
    .setValue(100)
    .setPosition(37, 62)
    .setSize(100, 19)
    .setBroadcast(true)
    ;
  // create a new button with name 'cleardisplay'
  cp5.addButton("ClearDisplay")
    .setLabel("Clear Display")
    .setBroadcast(false)
    .setValue(200)
    .setPosition(37, 87)
    .setSize(100, 19)
    .setBroadcast(true)
    ;
  //Create a new text field to show feedback from the controller
  feedbackText = cp5.addTextarea("feedback")
    .setSize(512, 37)
    .setText("Load image to start")
    //.setFont(createFont("arial", 12))
    .setLineHeight(14)
    .setColor(color(128))
    .setColorBackground(color(235, 100))
    .setColorForeground(color(245, 100))
    .setPosition(187, 37)
    ;
  //Create a new slider to set amplitude of waves drawn: default value is 2.4
  cp5.addSlider("amplitudeSlider")
    .setBroadcast(false)
    .setLabel("Wave amplitude")
    .setRange(1, 8)
    .setValue(2.4)
    .setPosition(37, 125)
    .setSize(100, 19)
    .setSliderMode(Slider.FLEXIBLE)
    .setDecimalPrecision(1)
    .setBroadcast(true)
    ;

  // reposition the Label for controller 'slider'
  cp5.getController("amplitudeSlider").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE).setPaddingX(0).setColor(color(128));

  cp5.addSlider("distanceSlider")
    .setBroadcast(false)
    .setLabel("Distance between rings")
    .setRange(5, 10)
    .setValue(5)
    .setNumberOfTickMarks(6)
    .setPosition(37, 163)
    .setSize(100, 19)
    .setSliderMode(Slider.FLEXIBLE)
    .setBroadcast(true)
    ;

  // reposition the Label for controller 'slider'
  cp5.getController("distanceSlider").getCaptionLabel().align(ControlP5.LEFT, ControlP5.TOP_OUTSIDE).setPaddingX(0).setColor(color(128));
}

//Button control event handler
public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
}

// Button Event - Open: Open image file dialogue
public void Open(int theValue) {
  clearDisplay();
  locImg="";
  selectInput("Select a file to process:", "fileSelected");
}

// Button Event - Draw: Convert image file to SVG
public void Draw(int theValue) {
  if (locImg == "") {
    feedbackText.setText("no image file is currently open!");
    feedbackText.update();
  } else {
    resizeImg();
    
// Rework to save in the same folder as original image
    outputSVGName=imageName+".svg";
    drawSVG();
    displaySVG();
  }
}

// Clear the display of any loaded images
public void ClearDisplay(int theValue) {
  clearDisplay();
}

//Recieve amplitude value from slider
public void amplitudeSlider(float theValue) {
  ampScale = theValue;
  println(ampScale);
}

//Recieve wave distance value from slider
public void distanceSlider(int theValue) {
  dist = theValue;
  println(dist);
}


//Redraw background elements to remove previous loaded PImage
void drawBackground () {
  noStroke();
  background(235);
  fill(245);
  rect(25, 25, 125, 750);
  fill(245);
  rect(175, 25, 537, 750);
}

void draw() {
  //System.gc();
}

//Opens input file selection window and draws selected image to screen
void fileSelected(File selection) {
  if (selection == null) {
    feedbackText.setText("Window was closed or the user hit cancel.");
    feedbackText.update();
  } else {
    locImg=selection.getAbsolutePath();
    feedbackText.setText(locImg+" was succesfully opened");
    feedbackText.update();
    sourceImg=loadImage(locImg);
    displayImg=loadImage(locImg);
    drawImg();
    
    // get the filename of the image and remove the extension
    // No check if extension exists
    // TODO: extract path to save SVG to later
    file = new File(locImg);
    imageName = file.getName();
    imageName = imageName.substring(0, imageName.lastIndexOf("."));
  }
}

// Function to creatve SVG file from loaded image file - Transparencys currently do not work as a mask colour
void drawSVG() {

  // Calculates the first point
  // currently just the center
  // TODO: create button to set center with mouse
  k = density/(dist/2);
  alpha = k;
  radius = dist/(360/k);
  x =  aradius*cos(radians(alpha))+sourceImg.width/2;
  y = -aradius*sin(radians(alpha))+sourceImg.height/2;

  // when have we reached the far corner of the image?
  // TODO: this will have to change if not centered
  endRadius = sqrt(pow((sourceImg.width/2), 2)+pow((sourceImg.height/2), 2));

  shapeOn = false;
  openSVG ();

  // Have we reached the far corner of the image?
  while (radius < endRadius) {
    k = (density/2)/radius ;
    alpha += k;
    radius += dist/(360/k);
    x =  radius*cos(radians(alpha))+sourceImg.width/2;
    y = -radius*sin(radians(alpha))+sourceImg.height/2;

    // Are we within the the image?
    // If so check if the shape is open. If not, open it
    if ((x>=0) && (x<sourceImg.width) && (y>=0) && (y<sourceImg.height)) {

      // Get the color and brightness of the sampled pixel
      c = sourceImg.get (int(x), int(y));
      b = brightness(c);
      b = map (b, 0, 255, dist*ampScale, 0);

      // Move up according to sampled brightness
      aradius = radius+(b/dist);
      xa =  aradius*cos(radians(alpha))+sourceImg.width/2;
      ya = -aradius*sin(radians(alpha))+sourceImg.height/2;

      // Move down according to sampled brightness
      k = (density/2)/radius ;
      alpha += k;
      radius += dist/(360/k);
      bradius = radius-(b/dist);
      xb =  bradius*cos(radians(alpha))+sourceImg.width/2;
      yb = -bradius*sin(radians(alpha))+sourceImg.height/2;

      // If the sampled color is the mask color do not write to the shape
      if (mask == c) {
        if (shapeOn) {
          closePolyline ();
          output.println("<!-- Mask -->");
        }
        shapeOn = false;
      } else {
        // Add vertices to shape
        if (shapeOn == false) {
          openPolyline ();
          shapeOn = true;
        }
        vertexPolyline (xa, ya);
        vertexPolyline (xb, yb);
      }

    } else {

      // We are outside of the image so close the shape if it is open
      if (shapeOn == true) {
        closePolyline ();
        output.println("<!-- Out of bounds -->");
        shapeOn = false;
      }
    }
  }
  if (shapeOn) closePolyline();
  closeSVG ();
  println(locImg+" was processed and saved as "+outputSVGName);
  feedbackText.setText(locImg+" was processed and saved as "+outputSVGName);
  feedbackText.update();
  System.gc();
}

void resizeImg() { 
  if ( sourceImg.width > sourceImg.height) {
    sourceImg.resize (1200, 0);
  } else {
    sourceImg.resize (0, 1200);
  }
}

void resizedisplayImg() { 
  if ( displayImg.width > displayImg.height) {
    displayImg.resize (512, 0);
  } else {
    displayImg.resize (0, 512);
  }
}

void displaySVG () {
  clearDisplay();
  String svgLocation = imageName + ".svg";
  outputSVG = loadShape(svgLocation);
  shape(outputSVG, 187, 85, 512, 512 * outputSVG.width / outputSVG.height);
  feedbackText.setText(locImg+" was processed and saved as "+sketchPath(outputSVGName));
  feedbackText.update();
}

void drawImg () {
  resizedisplayImg();
  //background(255);
  set(187, 85, displayImg);
}

void clearDisplay() {
  background(235);
  drawBackground();
  feedbackText.setText("Load image to start");
  System.gc();
}
