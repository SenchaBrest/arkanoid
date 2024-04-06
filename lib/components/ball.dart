import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/rendering.dart';
import 'package:flame/extensions.dart';

import '../forge2d_game_world.dart';
import '../utils/image_loader.dart';
import 'paddle.dart';
import 'dead_zone.dart';
import 'bonus.dart';



class BallManager extends Component {
  List<Ball> balls = [];
  final Vector2 position;
  final double radius;
  final String imagePath;

  BallManager({required this.position, required this.radius, required this.imagePath});

  Future<void> createBall({position, radius, linearVelocity}) async {
    final ball = Ball(
      radius: radius ?? this.radius,
      position: position ?? this.position,
      linearVelocity: linearVelocity,
      imagePath: imagePath,
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



class Ball extends BodyComponent<Forge2dGameWorld> with ContactCallbacks, ImageLoader{
  final Vector2 position;
  final Vector2? linearVelocity;
  final double radius;
  ui.Image? image;
  String imagePath;

  late double speed;
  static const maxSpeed = 20.0;
  static const minSpeed = 10.0;

  List<ui.Image?> imageList = [null];

  Ball({
    required this.position,
    required this.radius,
    this.linearVelocity,
    required this.imagePath
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    image = await ImageLoader.loadImage(imagePath);
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
      ..linearVelocity = linearVelocity ?? Vector2(0.0, 0.0)
    ..angularVelocity = 0;

    final ball = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(shape)
      ..restitution = 1.0
      ..density = 1.0;

    ball.createFixture(fixtureDef);
    return ball;
  }

  var destroy = false;
  Object? otherObject;

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Paddle) {
      if (gameRef.bonusState == BonusState.green) {
        body.linearVelocity = Vector2.zero();
        otherObject = other;
      }
    }
    if (other is DeadZone) {
      destroy = true;
      gameRef.gameState = GameState.lostTheBall;
    }
    speed = body.linearVelocity.length;
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

  @override
  void update(double dt) {
    super.update(dt);

    if (otherObject is Paddle && gameRef.bonusState == BonusState.green && !gameRef.isBallConnectedToThePaddle) {
      if (body.position.x - (otherObject as Paddle).body.position.x > (otherObject as Paddle).size.width / 2 - radius) {
        body.position.x = (otherObject as Paddle).body.position.x + (otherObject as Paddle).size.width / 2 - radius;
        body.position.y = position.y - radius;
      }
      else if ((otherObject as Paddle).body.position.x - body.position.x > (otherObject as Paddle).size.width / 2 - radius) {
        body.position.x = (otherObject as Paddle).body.position.x - (otherObject as Paddle).size.width / 2 + radius;
        body.position.y = position.y  - radius;
      }

      gameRef.jointDef
        ..initialize((otherObject as Paddle).body, body, (otherObject as Paddle).body.position, Vector2(1, 0))
        ..enableLimit = true
        ..lowerTranslation = 0
        ..upperTranslation = 0;
      gameRef.world.createJoint(PrismaticJoint(gameRef.jointDef));
      gameRef.isBallConnectedToThePaddle = true;

      otherObject = null;
    }

    if (!gameRef.isBallConnectedToThePaddle) {
      body.linearVelocity *= (1 + gameRef.accelerationRateForSpeed * dt);

      if (body.linearVelocity.length > maxSpeed) {
        body.linearVelocity = body.linearVelocity.normalized() * maxSpeed;
      }

      if (body.linearVelocity.length < minSpeed) {
        body.linearVelocity = body.linearVelocity.normalized() * minSpeed;
      }
    }
  }
}
