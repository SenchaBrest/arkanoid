import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../forge2d_game_world.dart';
import '../utils/image_loader.dart';
import 'arena.dart';
import 'bonus.dart';



class Paddle extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  Size size;
  final Vector2 position;
  ui.Image? image;

  bool movingLeft = false;
  bool movingRight = false;
  bool permissionToMovingLeft = true;
  bool permissionToMovingRight = true;

  Paddle({
    required this.size,
    required this.position,
    required String imagePath,
  }) {
    _loadImage(imagePath);
  }

  Future<void> _loadImage(String imagePath) async {
    image = await ImageLoader.loadImage(imagePath);
  }

  @override
  void render(Canvas canvas) {
    if (image != null) {
      final shape = body.fixtures.first.shape as PolygonShape;
      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        Rect.fromPoints(
          Offset(shape.vertices[0].x, shape.vertices[0].y),
          Offset(shape.vertices[2].x, shape.vertices[2].y),
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
      ..fixedRotation = true
      ..angularDamping = 1.0
      ..linearDamping = 0.0;

    final paddleBody = world.createBody(bodyDef);

    final shape = PolygonShape()
      ..setAsBox(
        size.width / 2.0,
        size.height / 2.0,
        Vector2(0.0, 0.0),
        0.0,
      );

    paddleBody.createFixture(FixtureDef(shape)
      ..density = 100.0
      ..friction = 0.0
      ..restitution = 1.0
      ..isSensor = false,
    );

    return paddleBody;
  }

  void updateBody({required Size newSize, required String imagePath, required bool isSensor}) {
    size = newSize;

    final shape = PolygonShape()
      ..setAsBox(
        size.width / 2.0,
        size.height / 2.0,
        Vector2(0.0, 0.0),
        0.0,
      );
    body.destroyFixture(body.fixtures.first);
    body.createFixture(FixtureDef(shape)
      ..density = 100.0
      ..friction = 0.0
      ..restitution = 1.0
      ..isSensor = isSensor
    );
    _loadImage(imagePath);
  }

  bool handleKeyboardEvents(KeyEvent event) {
    if (gameRef.gameState == GameState.running) {
      if (event is KeyRepeatEvent || event is KeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (permissionToMovingLeft) {
            body.linearVelocity = Vector2(-20, 0);
            permissionToMovingRight = true;
            movingLeft = true;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (permissionToMovingRight) {
            body.linearVelocity = Vector2(20, 0);
            permissionToMovingLeft = true;
            movingRight = true;
          }
        }
      }
      if (event is KeyUpEvent && !gameRef.toTheNextLevel) {
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          movingLeft = false;
        }
        else if(event.logicalKey == LogicalKeyboardKey.arrowRight) {
          movingRight = false;
        }

        if (!movingLeft && !movingRight) {
          body.linearVelocity = Vector2.zero();
        }
      }
    }
    return true;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Arena) {
      if (!gameRef.toTheNextLevel) {
        if (gameRef.bonusState == BonusState.pink &&
            body.position.x > gameRef.size.x / 2) {
          permissionToMovingLeft = false;
          permissionToMovingRight = false;
          gameRef.makePaddleSensorAndDestroyBall = true;
        }
        else {
          body.linearVelocity = Vector2.zero();
        }
        if (body.position.x < gameRef.size.x / 2) {
          permissionToMovingLeft = false;
        }
        else {
          permissionToMovingRight = false;
        }
      }
    }
  }

  @override
  void onMount() {
    super.onMount();

    HardwareKeyboard.instance.addHandler(handleKeyboardEvents);
  }

  void reset() {
    updateBody(
        newSize: size,
        imagePath: 'assets/images/paddle/paddleOriginal.png',
        isSensor: false,
    );
    body.setTransform(position, angle);
    body.angularVelocity = 0.0;
    body.linearVelocity = Vector2.zero();
    permissionToMovingLeft = true;
    permissionToMovingRight = true;
    movingLeft = false;
    movingRight = false;
  }
}
