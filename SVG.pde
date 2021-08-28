//SVG Output 1.0

PrintWriter output;                        // Output stream for SVG Export
int shapeLen = 1000;                       // Maximum number of vertices per shape
int shapeCount = 1;
boolean shapeOn = false;                   // Keeps track of a shape is open or closed

void openSVG () {
  output = createWriter(outputSVGName); 
  output.println("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
  output.println("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
  output.println("<svg width=\"1200 px\" height=\"1200 px\" viewBox=\"0 0 1200 1200\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">");
}

void openPolyline () {
  output.println("  <polyline fill=\"none\" stroke=\"#000000\" points=\"");
}

void vertexPolyline (float x, float y) {
  // If the shape has gotten too long close it and open a new one
  if (shapeCount%shapeLen == 0 && shapeOn) {
    output.print("    ");
    output.print(x);
    output.print(",");
    output.println(y);
    endShape ();
    closePolyline ();
    output.println("<!-- Maximum Shape Length -->");
    beginShape ();
    openPolyline ();
  }
  output.print("    ");
  output.print(x);
  output.print(",");
  output.println(y);
  shapeCount++;
}

void closePolyline () {
  output.println("  \" />");
  shapeCount = 1;
}

void closeSVG () {
  output.println("</svg>");
  output.flush(); 						// Writes the remaining data to the file
  output.close(); 						// Closes the file
}
