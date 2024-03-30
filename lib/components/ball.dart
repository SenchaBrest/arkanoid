import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/rendering.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../forge2d_game_world.dart';
import 'paddle.dart';
import 'dead_zone.dart';
import 'bonus.dart';

class BallManager extends Component {
  List<Ball> balls = [];
  final Vector2 position;
  final double radius;

  BallManager({required this.position, required this.radius});

  Future<void> createBall({position, radius, linearVelocity}) async {
    final ball = Ball(
      radius: radius ?? this.radius,
      position: position ?? this.position,
      linearVelocity: linearVelocity
    );
    await add(ball);
    balls.add(ball);
  }

  void removeBall(Ball ballToRemove) {
    final index = balls.indexOf(ballToRemove);
    if (index != -1) {
      balls.removeAt(index);
      remove(ballToRemove);
    }
  }

  void reset() {
    for (final ball in [...balls]) {
      if (ball.destroy) {
        removeBall(ball);
      }
    }
  }
}

class Ball extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Vector2 position;
  final Vector2? linearVelocity;
  final double radius;
  ui.Image? image;

  Ball({required this.position, required this.radius, this.linearVelocity}) {
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/ball_image.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    image = frame.image;
  }

  @override
  void render(Canvas canvas) {
    if (image != null) {
      final circle = body.fixtures.first.shape as CircleShape;
      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        Rect.fromCircle(
          center: circle.position.toOffset(),
          radius: radius,
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
      ..linearVelocity = linearVelocity ?? Vector2(0.0, 0.0);

    final ball = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(shape)
      ..restitution = 1.0
      ..density = 1.0;

    ball.createFixture(fixtureDef);
    return ball;
  }

  var destroy = false;

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Paddle) {
      if (gameRef.bonusState == BonusState.green) {
        // body.linearVelocity = Vector2(0, 0);
        // gameRef.isBallOnThePaddle = true;
      }
      body.position;
      other.position;
    }
    if (other is DeadZone) {
      destroy = true;
      gameRef.gameState = GameState.lostTheBall;
    }
  }

  void slowDown() {
    body.applyLinearImpulse(-body.linearVelocity / 2);
  }

  void speedUp() {
    body.applyLinearImpulse(body.linearVelocity);
  }

  void reset() {
    body.setTransform(position, angle);
    body.angularVelocity = 0.0;
    body.linearVelocity = Vector2.zero();
  }
}
