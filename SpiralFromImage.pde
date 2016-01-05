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
 
 Todo:
   - Choose centerpoint with mouse or in code
   - Remove PDF export completely
  
 SpiralfromImage is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with SpiralfromImage.  If not, see <http://www.gnu.org/licenses/>.
 
 jan@krummrey.de
 http://jan.krummrey.de
 */

import processing.pdf.*;

PImage sourceImg;                          // Source image
color c;                                   // Sampled color
float b;                                   // Sampled brightness
float dist = 5;                            // Distance between rings
float radius = dist/2;                     // Current radius
float aradius;                             // Radius with brighness applied up
float bradius;                             // Radius with brighness applied down
float alpha = 0;                           // Initial rotation
float density = 75;                        // Density
int counter=0;                             // Counts the samples
int shapeLen = 5000;                       // Maximum number of vertices per shape
boolean shapeOn = false;                   // Keeps track of a shape is open or closed
float ampScale = 2.4;                      // Controls the amplitude
float x, y, xa, ya, xb, yb, k;
float endRadius;
color mask = color (255, 255, 255);        // This color will not be drawn
PrintWriter output;                        // Output stream for SVG Export
boolean exportPDF = false;                 // Also export a PDF

void setup() {
  size(1024, 1024);
  background(255); 
  noFill();
  sourceImg=loadImage("input.jpg");

  // Scale to window size
  if ( sourceImg.width > sourceImg.height) {
    sourceImg.resize (1024, 0);
  } else {
    sourceImg.resize (0, 1024);
  }

  //when have we reached the far corner of the image?
  endRadius = sqrt(pow((sourceImg.width/2), 2)+pow((sourceImg.height/2), 2));

  // Calculates the first point and adds it to the shape
  // currently just the center
  k = density/radius ;
  alpha += k;
  radius += dist/(360/k);
  x =  aradius*cos(radians(alpha))+sourceImg.width/2;
  y = -aradius*sin(radians(alpha))+sourceImg.height/2;

if (exportPDF) beginRecord( PDF, "output.pdf");
if (exportPDF)   beginShape ();
  shapeOn = true;
  vertex (x, y);
  openSVG ();
  openPolyline();
  vertexPolyline(x, y);
}
void draw() {
  // Have we reached the far corner of the image?
  while (radius < endRadius) {
    k = (density/2)/radius ;
    alpha += k;
    radius += dist/(360/k);
    x =  radius*cos(radians(alpha))+sourceImg.width/2;
    y = -radius*sin(radians(alpha))+sourceImg.height/2;

    // Are we within the the image?
    // If so check if the shape is open. If not, open it
    if ((x>=0) && (x<sourceImg.width) && (y>00) && (y<sourceImg.height)) {
      counter++;

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
        if (exportPDF) endShape ();
        if (shapeOn) {
          closePolyline ();
          output.println("<!-- Mask -->");
        }
        shapeOn = false;
      } else {
        // Add vertices to shape
        if (shapeOn == false) {
          if (exportPDF) beginShape ();
          openPolyline ();
          shapeOn = true;
        }
        vertex (xa, ya);
        vertex (xb, yb);
        vertexPolyline (xa, ya);
        vertexPolyline (xb, yb);
      }

      // If the shape has gotten too long close it and open a new one
      if (counter%shapeLen == 0 && shapeOn) {
        if (exportPDF) endShape ();
        closePolyline ();
        output.println("<!-- Max ShapeLen -->");
        if (exportPDF) beginShape ();
        openPolyline ();
      }
    } else {

      // We are outside of the image so close the shape if it is open
      if (shapeOn == true) {
        if (exportPDF) endShape ();
        closePolyline ();
        output.println("<!-- Out of bounds -->");
        shapeOn = false;
      }
    }
  }
  if (exportPDF) endShape();
  if (exportPDF) endRecord();
  if (shapeOn) closePolyline();
  closeSVG ();
  exit();
}

void openSVG () {
  output = createWriter("output.svg"); 
  output.println("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
  output.println("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
  output.println("<svg width=\"px\" height=\"px\" viewBox=\"0 0 1200 400\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">");
}

void openPolyline () {
  output.println("  <polyline fill=\"none\" stroke=\"#000000\" points=\"");
}

void vertexPolyline (float x, float y) {
  output.print("    ");
  output.print(x);
  output.print(",");
  output.println(y);
}

void closePolyline () {
  output.println("  \" />");
}

void closeSVG () {
  output.println("</svg>");
  output.flush(); // Writes the remaining data to the file
  output.close(); // Finishes the file
}
