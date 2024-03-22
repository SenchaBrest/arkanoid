// Copyright (c) 2022 Razeware LLC

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical
// or instructional purposes related to programming, coding, application
// development, or information technology.  Permission for such use, copying,
// modification, merger, publication, distribution, sublicensing, creation of
// derivative works, or sale is expressly withheld.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../forge2d_game_world.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:ui' as ui;

class Arena extends BodyComponent<Forge2dGameWorld> {
  Vector2? size;
  ui.Image? image;

  Arena({this.size}) {
    assert(size == null || size!.x >= 1.0 && size!.y >= 1.0);
  }

  late Vector2 arenaSize;

  @override
  Future<void> onLoad() async {
    arenaSize = size ?? gameRef.size;
    await loadImage();
    return super.onLoad();
  }

  Future<void> loadImage() async {
    final ByteData data = await rootBundle.load('assets/arena.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    image = frameInfo.image;
  }

  @override
  void render(Canvas canvas) {
    if (image != null) {
      final Rect destRect = Rect.fromLTWH(0, 0, arenaSize.x, arenaSize.y);
      final Rect srcRect = Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble());
      canvas.drawImageRect(image!, srcRect, destRect, Paint()); // Use drawImageRect

      // Alternatively, you can use drawImage to fit the image within the destination rect
      // canvas.drawImage(image!, Offset.zero, Paint()); // Use drawImage with fit argument
    }
  }

  @override
  Body createBody() {
    final ratio = Vector2(0.0, 0.0);
    ratio.x = (1033 - 43) / 1033;
    ratio.y = (1060 - 43) / 1060;

    final bodyDef = BodyDef()
      ..position = Vector2(0, 0)
      ..type = BodyType.static;

    final arenaBody = world.createBody(bodyDef);

    final vertices = <Vector2>[
      Vector2(arenaSize.x * ratio.x, arenaSize.y * ratio.y),
      Vector2(arenaSize.x * (1 - ratio.x), arenaSize.y * ratio.y),
      Vector2(arenaSize.x * (1 - ratio.x), arenaSize.y * (1 - ratio.y)),
      Vector2(arenaSize.x * ratio.x, arenaSize.y * (1 - ratio.y)),
    ];

    final chain = ChainShape()..createLoop(vertices);

    for (var index = 0; index < chain.childCount; index++) {
      arenaBody.createFixture(
        FixtureDef(chain.childEdge(index))
          ..density = 2000.0
          ..friction = 0.0
          ..restitution = 0.4,
      );
    }

    return arenaBody;
  }
}
