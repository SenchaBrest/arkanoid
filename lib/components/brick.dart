import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';

import '../forge2d_game_world.dart';
import '../utils/image_loader.dart';
import 'ball.dart';
import 'bonus.dart';
import 'bullet.dart';



enum BrickColor {
  gray,
  red,
  yellow,
  blue,
  pink,
  green,
}

class Brick extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Size size;
  final Vector2 position;
  final BrickColor brickColor;
  late final String imagePath;
  late int brickLives;
  late final int value;
  ui.Image? image;

  Brick({
    required this.size,
    required this.position,
    required this.brickColor,

  }) {
    imagePath = 'assets/images/bricks/${brickColor.index}.png';
    brickLives = (brickColor == BrickColor.gray) ? 4 : 1;

    switch(brickColor) {
      case BrickColor.gray:
        value = 50;
        break;
      case BrickColor.red:
        value = 90;
        break;
      case BrickColor.yellow:
        value = 120;
        break;
      case BrickColor.blue:
        value = 100;
        break;
      case BrickColor.pink:
        value = 110;
        break;
      case BrickColor.green:
        value = 80;
        break;
    }
  }

  @override
  Future<void> onLoad() async {
    image = await ImageLoader.loadImage(imagePath);
    return super.onLoad();
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
    // if (other is Ball || other is Bullet) {
    if (other is Ball) {
      brickLives--;
      if (brickLives == 0) {
        destroy = true;

        gameRef.updateScore(value);

        if (gameRef.isBonusesFall && brickColor != BrickColor.gray) {
          double probability = 0.5;
          double randomValue = Random().nextDouble();

          if (randomValue < probability) {
            List<BonusState> bonusColors = BonusState.values;
            int randomIndex = Random().nextInt(bonusColors.length - 1);
            Bonus(
                size: size,
                position: position,
                bonusState: bonusColors[randomIndex]
            ).addToParent(parent!);
          }
        }
      }
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
