import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../forge2d_game_world.dart';
import '../utils/image_loader.dart';
import 'dead_zone.dart';
import 'paddle.dart';



enum BonusState {
  blue,
  gray,
  green,
  lightBlue,
  orange,
  pink,
  red,
  none,
}

class Bonus extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Size size;
  final Vector2 position;
  final BonusState bonusState;
  late final String gifPath;
  List<ui.Image> frames = [];
  int currentFrameIndex = 0;
  double timeSinceLastFrame = 0.0;
  double frameDuration = 0.5;

  Bonus({
    required this.size,
    required this.position,
    required this.bonusState,
  }) {
    gifPath = 'assets/animations/bonuses/${bonusState.index}.gif';
  }

  @override
  Future<void> onLoad() async {
    frames = await ImageLoader.loadGif(gifPath);
    return super.onLoad();
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
      gameRef.bonusState = bonusState;
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
