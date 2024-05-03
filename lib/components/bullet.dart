import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';

import '../forge2d_game_world.dart';
import '../utils/image_loader.dart';
import 'bonus.dart';



class BulletManager extends Component {
  void createBullets({
    required Size arenaSize,
    required paddlePosition,
    required Size paddleSize,
    required String imagePath,
  }) {
    final bulletLeftSize = Size(arenaSize.width * 5 / 1033, arenaSize.height * 22 / 1060);
    final bulletLeftPosition = paddlePosition - Vector2(43 / 135 * paddleSize.width, 1);

    add(
        Bullet(
          size: bulletLeftSize,
          position: bulletLeftPosition,
          imagePath: imagePath,
        ));

    final bulletRightSize = Size(arenaSize.width * 5 / 1033, arenaSize.height * 22 / 1060);
    final bulletRightPosition = paddlePosition + Vector2(43 / 135 * paddleSize.width, -1);

    add(
        Bullet(
          size: bulletRightSize,
          position: bulletRightPosition,
          imagePath: imagePath,
        ));
  }

  void reset() {
    for (final child in [...children]) {
      if (child is Bullet) {
        remove(child);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final child in [...children]) {
      if (child is Bullet && child.destroy) {
        remove(child);
      }
    }
  }
}



class Bullet extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Size size;
  final Vector2 position;
  late String imagePath;
  ui.Image? image;


  Bullet({
    required this.size,
    required this.position,
    required this.imagePath,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    image = await ImageLoader.loadImage(imagePath);
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
      ..type = BodyType.dynamic
      ..position = position
      ..linearVelocity = Vector2(0, -100)
      ..bullet = true;

    final bulletBody = world.createBody(bodyDef);

    final shape = PolygonShape()
      ..setAsBox(
        size.width / 2.0,
        size.height / 2.0,
        Vector2(0.0, 0.0),
        0.0,
      );

    bulletBody.createFixture(
      FixtureDef(shape)
        ..restitution = 0.0
        ..density = 0.0
        ..isSensor = false,
    );

    return bulletBody;
  }

  bool destroy = false;
  @override
  void beginContact(Object other, Contact contact) {
    if (other is! Bonus) {
      destroy = true;
    }
  }
}
