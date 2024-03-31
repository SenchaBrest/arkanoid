import 'dart:async';
import 'dart:math';
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

  void _removeBall(Ball ballToRemove) {
    final index = balls.indexOf(ballToRemove);
    if (index != -1) {
      balls.removeAt(index);
      remove(ballToRemove);
    }
  }

  void removeBall() {
    for (final ball in [...balls]) {
      if (ball.destroy) {
        _removeBall(ball);
      }
    }
  }

  void reset() {
    for (final ball in [...balls]) {
      _removeBall(ball);
    }
    createBall();
  }
}

class Ball extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Vector2 position;
  final Vector2? linearVelocity;
  final double radius;
  ui.Image? image;

  final double speed = sqrt(2 * 20 * 20);

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
    // if (other is Paddle) {
    //
    // }
    if (other is DeadZone) {
      destroy = true;
      gameRef.gameState = GameState.lostTheBall;
    }
  }

  @override
  void endContact(Object other, [Contact? contact]) {
    if (other is Paddle) {
      // TODO: need more physical angles

      // if u wanna normal physic just commented this if-else code
      if (body.position.x > other.body.position.x) {
        if (body.position.x + other.size.width * 2 / 6 > other.body.position.x) {
          body.linearVelocity = Vector2(7, -3);
        } else if (body.position.x + other.size.width * 1 / 6 > other.body.position.x) {
          body.linearVelocity = Vector2(3, -3);
        } else {
          body.linearVelocity = Vector2(3, -7);
        }
      } else {
        if (body.position.x + other.size.width * 2 / 6 < other.body.position.x) {
          body.linearVelocity = Vector2(-3, -7);
        } else if (body.position.x + other.size.width * 1 / 6 < other.body.position.x) {
          body.linearVelocity = Vector2(-3, -3);
        } else {
          body.linearVelocity = Vector2(-7, -3);
        }
      }
    }

    if (!gameRef.isBallConnectedToThePaddle) {
      body.linearVelocity *= (speed / body.linearVelocity.length);
    }
  }

  void slowDown() {
    body.applyLinearImpulse(-body.linearVelocity / 2);
  }

  void speedUp() {
    body.applyLinearImpulse(body.linearVelocity);
  }
}
