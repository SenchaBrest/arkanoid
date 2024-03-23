import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';

import 'package:flame_forge2d/flame_forge2d.dart';
import '../forge2d_game_world.dart';
import 'dead_zone.dart';
import 'paddle.dart';

enum BonusColor {
  blue,
  gray,
  green,
  lightBlue,
  orange,
  pink,
  red,
}

class Bonus extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Size size;
  final Vector2 position;
  final BonusColor bonusColor;
  List<ui.Image> frames = [];
  int currentFrameIndex = 0;
  double timeSinceLastFrame = 0.0;
  double frameDuration = 0.5;

  Bonus({
    required this.size,
    required this.position,
    required this.bonusColor,
  }) {
    _loadImage();
  }

  void _loadImage() async {
    final data = await rootBundle.load('assets/bonuses/${bonusColor.index}.gif');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    for (int i = 0; i < codec.frameCount; i++) {
      final frame = await codec.getNextFrame();
      frames.add(frame.image);
    }
  }

  @override
  void update(double dt) {
    timeSinceLastFrame += dt;
    if (timeSinceLastFrame >= frameDuration) {
      timeSinceLastFrame = 0.0;
      currentFrameIndex = (currentFrameIndex + 1) % frames.length;
    }
  }

  var destroy = false;

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Paddle) {
      destroy = true;
    }
    if (other is DeadZone) {
      destroy = true;
    }
  }

  @override
  void render(Canvas canvas) {
    if (frames.isNotEmpty) {
      if (body.fixtures.isEmpty) {
        return;
      }

      final rectangle = body.fixtures.first.shape as PolygonShape;

      canvas.drawImageRect(
        frames[currentFrameIndex],
        Rect.fromLTWH(0, 0, frames[currentFrameIndex].width.toDouble(), frames[currentFrameIndex].height.toDouble()),
        Rect.fromCenter(
          center: rectangle.centroid.toOffset(),
          width: size.width,
          height: size.height,
        ),
        Paint(),
      );
    }
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..userData = this
      ..type = BodyType.dynamic
      ..position = position
      ..linearVelocity = Vector2(0.0, 5.0);


    final bonusBody = world.createBody(bodyDef);

    final shape = PolygonShape()
      ..setAsBox(
        size.width / 2.0,
        size.height / 2.0,
        Vector2(0.0, 0.0),
        0.0,
      );

    bonusBody.createFixture(
      FixtureDef(shape)
        ..density = 0.0
        ..friction = 0.0
        ..restitution = 0.0
        ..isSensor = true,
    );

    return bonusBody;
  }
}
