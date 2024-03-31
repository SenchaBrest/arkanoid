import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

import '../forge2d_game_world.dart';
import 'bullet.dart';
import 'paddle.dart';

class Arena extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
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
      canvas.drawImageRect(image!, srcRect, destRect, Paint());
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Bullet) {
      gameRef.remove(other);
    }
    // if (other is Paddle) {
    //   other.body.linearVelocity = Vector2.zero();
    //   print(0);
    // }
  }

  @override
  Body createBody() {
    final ratio = Vector2(0.0, 0.0);
    ratio.x = (1033 - 43) / 1033;
    ratio.y = (1060 - 43) / 1060;

    final bodyDef = BodyDef()
      ..userData = this
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
