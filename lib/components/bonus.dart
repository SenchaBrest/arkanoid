import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';

import 'package:flame_forge2d/flame_forge2d.dart';
import '../forge2d_game_world.dart';


class Bonus extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Size size;
  final Vector2 position;
  final String bonusImageId;
  ui.Image? image;

  Bonus({
    required this.size,
    required this.position,
    required this.bonusImageId,
  }) {
    _loadImage(bonusImageId);
  }

  void _loadImage(String bonusImageId) async {
    final data = await rootBundle.load('assets/bonuses/$bonusImageId.gif');
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

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..userData = this
      ..type = BodyType.kinematic
      ..position = position
      ..linearVelocity = Vector2(0.0, 1.0);


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
