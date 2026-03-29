import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 512, height: 512);
  
  // Emerald 700 background
  img.fill(image, color: img.ColorRgb8(4, 120, 87));

  // Draw a minimalist golf-themed shape
  // White circle (golf ball outline)
  img.drawCircle(image, x: 256, y: 256, radius: 180, color: img.ColorRgb8(255, 255, 255));
  
  // Invert/Subtract inner circle to make it an outline if we want
  img.drawCircle(image, x: 256, y: 256, radius: 160, color: img.ColorRgb8(4, 120, 87));

  // Draw a simple flag/stick
  img.drawLine(image, x1: 256, y1: 140, x2: 256, y2: 380, color: img.ColorRgb8(255, 255, 255));
  
  // Minimalist flag triangle
  img.drawLine(image, x1: 256, y1: 140, x2: 320, y2: 180, color: img.ColorRgb8(255, 255, 255));
  img.drawLine(image, x1: 320, y1: 180, x2: 256, y2: 220, color: img.ColorRgb8(255, 255, 255));

  File('assets/images/app_icon.png').writeAsBytesSync(img.encodePng(image));
  print('App icon generated at assets/images/app_icon.png');
}
