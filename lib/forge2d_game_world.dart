import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'components/arena.dart';
import 'components/ball.dart';
import 'components/brick_wall.dart';
import 'components/paddle.dart';
import 'components/dead_zone.dart';
import 'components/life.dart';
import 'components/bonus.dart';
import 'components/bullet.dart';

enum GameState {
  initializing,
  ready,
  running,
  paused,
  won,
  lost,
  lostTheBall,
}

class Forge2dGameWorld extends Forge2DGame with HasDraggables, HasTappables {
  Forge2dGameWorld() : super(gravity: Vector2.zero(), zoom: 20);

  GameState gameState = GameState.initializing;
  BonusState bonusState = BonusState.none;
  BonusState _previousBonusState = BonusState.none;

  late final Arena _arena;
  late final BallManager _balls;
  late final BrickWall _brickWall;
  late final DeadZone _deadZone;
  late final Paddle _paddle;
  late final LifeManager _lives;
  late Bullet _bulletLeft;
  late Bullet _bulletRight;

  bool isBallConnectedToThePaddle = false;
  bool isBonusesFall = true;
  double accelerationRateForSpeed = 0.0;

  var jointDef = RevoluteJointDef();

  @override
  Future<void> onLoad() async {
    await _initializeGame();
  }

  Future<void> _initializeGame() async {
    final paddingRatio = Vector2(0.0, 0.0);
    paddingRatio.x = 43 / 1033;
    paddingRatio.y = 44 / 1060;

    _arena = Arena();
    await add(_arena);

    final brickWallSize = Size(
        size.x * (1 - 2 * paddingRatio.x),
        size.y * 255 / 1060,
    );
    final brickWallPosition = Vector2(
        size.x * paddingRatio.x,
        size.y * paddingRatio.y + size.y * 135 / 1060,
    );
    _brickWall = BrickWall(
      position: brickWallPosition,
      size: brickWallSize,
      rows: 6,
      columns: 11,
    );
    await add(_brickWall);

    final deadZoneSize = Size(
        size.x * (1 - 2 * paddingRatio.x),
        size.y * (1 - paddingRatio.y - 940 / 1060)
    );
    final deadZonePosition = Vector2(
      size.x / 2.0,
      size.y - deadZoneSize.height / 2.0,
    );
    _deadZone = DeadZone(
      size: deadZoneSize,
      position: deadZonePosition,
    );
    await add(_deadZone);

    final paddleSize = Size(size.x * 135 / 1033, size.y * 33 / 1060);
    final paddlePosition = Vector2(
      size.x / 2.0,
      size.y - deadZoneSize.height - paddleSize.height / 2.0,
    );
    _paddle = Paddle(
      size: paddleSize,
      position: paddlePosition,
      imagePath: 'assets/paddle/paddleOriginal.png',
    );
    await add(_paddle);

    final ballPosition = Vector2(
        size.x / 2.0,
        size.y - deadZoneSize.height - paddleSize.height,
    );
    _balls = BallManager(
      radius: 0.5 * size.x * 27 / 1033,
      position: ballPosition,
    );
    await _balls.createBall();
    await add(_balls);

    final lifeManagerSize = Size(
      size.x * (1 - 2 * paddingRatio.x),
      size.y * 16 / 1060,
    );
    final lifeManagerPosition = Vector2(
      size.x * paddingRatio.x,
      size.y * paddingRatio.y + size.y * 999 / 1060,
    );
    _lives = LifeManager(
      position: lifeManagerPosition,
      size: lifeManagerSize,
    );
    await add(_lives);

    gameState = GameState.ready;
    overlays.add('PreGame');
  }

  Future<void> applyBonus() async {
    if (bonusState != _previousBonusState) {
      switch (_previousBonusState) {
        case BonusState.blue:
        case BonusState.red:
          final paddleSize = Size(size.x * 135 / 1033, size.y * 33 / 1060);
          _paddle.updateBody(
            newSize: paddleSize,
            imagePath: 'assets/paddle/paddleOriginal.png',
          );
          break;
        case BonusState.gray:
          break;
        case BonusState.green:
          break;
        case BonusState.lightBlue:
          break;
        case BonusState.orange:
          accelerationRateForSpeed = 0.5;
          break;
        case BonusState.pink:
          break;
        case BonusState.none:
          break;
      }

      switch (bonusState) {
        case BonusState.blue:
          break;
        case BonusState.gray:
          _lives.addLife();
          bonusState = BonusState.none;
          break;
        case BonusState.green:
          break;
        case BonusState.lightBlue:
          isBonusesFall = false;
          _brickWall.resetOnlyBonuses();

          final ballPosition = _balls.balls.first.body.position;

          const alpha = 0.5;
          var v = _balls.balls.first.body.linearVelocity;
          var u = Vector2(
              -_balls.balls.first.body.linearVelocity.y,
              _balls.balls.first.body.linearVelocity.x
          );

          await _balls.createBall(
            position: ballPosition,
            linearVelocity: (v * cos(alpha) + u * sin(alpha)),
          );
          await _balls.createBall(
            position: ballPosition,
            linearVelocity: (v * cos(alpha) - u * sin(alpha)),
          );
          break;
        case BonusState.orange:
          accelerationRateForSpeed = -0.5;
          break;
        case BonusState.pink:

          break;
        case BonusState.red:
          final paddleSize = Size(size.x * 135 / 1033, size.y * 33 / 1060);
          _paddle.updateBody(
            newSize: paddleSize,
            imagePath: 'assets/paddle/paddleWithLaser.png',
          );
          break;
        case BonusState.none:
          break;
      }

      _previousBonusState = bonusState;
    }
  }

  void createBullets() {
    var bulletLeftSize = Size(size.x * 5 / 1033, size.y * 22 / 1060);
    var bulletLeftPosition =
        _paddle.body.position - Vector2(43 / 135 * _paddle.size.width, 1);//22

    _bulletLeft = Bullet(
      size: bulletLeftSize,
      position: bulletLeftPosition,
      imagePath: 'assets/paddle/bullet.png',
    );
    add(_bulletLeft);

    var bulletRightSize = Size(size.x * 5 / 1033, size.y * 22 / 1060);
    var bulletRightPosition =
        _paddle.body.position + Vector2(43 / 135 * _paddle.size.width, -1);//113

    _bulletRight = Bullet(
      size: bulletRightSize,
      position: bulletRightPosition,
      imagePath: 'assets/paddle/bullet.png',
    );
    add(_bulletRight);
  }

  Future<void> resetGame() async {
    gameState = GameState.initializing;

    _balls.reset();
    _paddle.reset();
    await _brickWall.reset();
    _lives.reset();

    for (final child in [...children]) {
      if (child is Bullet) {
        for (final fixture in [...child.body.fixtures]) {
          child.body.destroyFixture(fixture);
        }
        world.destroyBody(child.body);
        remove(child);
      }
    }

    isBonusesFall = true;
    accelerationRateForSpeed = 0.0;

    gameState = GameState.ready;
    bonusState = BonusState.none;

    overlays.remove(overlays.activeOverlays.first);
    overlays.add('PreGame');

    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.lostTheBall) {
      _balls.removeBall();
      if (_balls.balls.length == 1) {
        isBonusesFall = true;
        bonusState = BonusState.none;
      }
      if (_balls.balls.isEmpty) {
        pauseEngine();
        if (_lives.isNotEmpty()) {
          _lives.removeLife();
          _paddle.reset();
          _balls.createBall();
          _brickWall.resetOnlyBonuses();

          isBonusesFall = true;
          accelerationRateForSpeed = 0.0;

          gameState = GameState.ready;
          bonusState = BonusState.none;

          overlays.add('PreGame');
          resumeEngine();
        }
        else {
          gameState = GameState.lost;
        }
      }
      else {
        gameState = GameState.running;
      }
    }

    if (gameState == GameState.lost || gameState == GameState.won) {
      pauseEngine();

      overlays.add('PostGame');
    }

    applyBonus();
  }

  bool handleKeyboardEvents(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (gameState == GameState.running) {
          if (_paddle.body.joints.isNotEmpty) {
            final joint = _paddle.body.joints.first;
            world.destroyJoint(joint);
            _balls.balls.last.body.applyLinearImpulse(Vector2(-sqrt(200), -sqrt(200)));
            isBallConnectedToThePaddle = false;
          }

          if (bonusState == BonusState.red) {
            createBullets();
          }
        }
        if (gameState == GameState.ready) {
          overlays.remove(overlays.activeOverlays.first);
          jointDef
            ..initialize(_paddle.body, _balls.balls.last.body, _paddle.body.position)
            ..enableLimit = true
            ..lowerAngle = 0
            ..upperAngle = 0;
          world.createJoint(RevoluteJoint(jointDef));
          isBallConnectedToThePaddle = true;
          gameState = GameState.running;
        }
      }
    }
    return true;
  }

  @override
  void onMount() {
    super.onMount();

    HardwareKeyboard.instance.addHandler(handleKeyboardEvents);
  }
}
