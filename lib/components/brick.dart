import 'dart:ui' as ui;


import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';
import '../forge2d_game_world.dart';
import 'ball.dart';
import 'bonus.dart';

import 'package:flame/components.dart';



class Brick extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Size size;
  final Vector2 position;
  final int brickImageId;
  ui.Image? image;

  Brick({
    required this.size,
    required this.position,
    required this.brickImageId,

  }) {
    _loadImage(brickImageId);
  }

  Future<void> _loadImage(int brickImageId) async {
    final data = await rootBundle.load('assets/bricks/$brickImageId.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    image = frame.image;
  }

  @override
  void render(Canvas canvas) {
    if (image != null) {
      if (body.fixtures.isEmpty) {
        return;
      }

      final rectangle = body.fixtures.first.shape as PolygonShape;

      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        Rect.fromCenter(
          center: rectangle.centroid.toOffset(),
          width: size.width,
          height: size.height,
        ),
        Paint(),
      );
    }
  }

  var destroy = false;

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Ball) {
      destroy = true;
      Bonus(size: size, position: position, bonusImageId: 'blue').addToParent(parent!);
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..userData = this
      ..type = BodyType.static
      ..position = position
      ..angularDamping = 1.0
      ..linearDamping = 1.0;

    final brickBody = world.createBody(bodyDef);

    final shape = PolygonShape()
      ..setAsBox(
        size.width / 2.0,
        size.height / 2.0,
        Vector2(0.0, 0.0),
        0.0,
      );

    brickBody.createFixture(
      FixtureDef(shape)
        ..density = 100.0
        ..friction = 0.0
        ..restitution = 0.1,
    );

    return brickBody;
  }
}
