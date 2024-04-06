import 'dart:ui' as ui;
import 'package:flutter/services.dart' show ByteData, rootBundle;



class ImageLoader {
  static Future<ui.Image?> loadImage(String imagePath) async {
    final ByteData data = await rootBundle.load(imagePath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  static Future<List<ui.Image>> loadGif(String gifPath) async {
    final data = await rootBundle.load(gifPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final List<ui.Image> frames = [];
    for (int i = 0; i < codec.frameCount; i++) {
      final frame = await codec.getNextFrame();
      frames.add(frame.image);
    }
    return frames;
  }
}
