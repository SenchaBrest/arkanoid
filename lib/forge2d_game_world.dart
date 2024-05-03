import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'components/score.dart';



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

  late final Score _score;
  late final Size _scoreSize;
  late final Vector2 _scorePosition;

  late final Arena _arena;
  late final Size _arenaSize;
  late final Vector2 _arenaPosition;

  late final BrickWall _brickWall;
  late final Size _brickWallSize;
  late final Vector2 _brickWallPosition;

  late final DeadZone _deadZone;
  late final Size _deadZoneSize;
  late final Vector2 _deadZonePosition;

  late final LifeManager _lives;
  late final Size _livesSize;
  late final Vector2 _livesPosition;

  late final Paddle _paddle;
  late final Size _paddleSize;
  late final Vector2 _paddlePosition;

  late final BallManager _balls;
  late final double _ballSize;
  late final Vector2 _ballPosition;

  late BulletManager _bullets;

  bool isBallConnectedToThePaddle = false;
  bool isBonusesFall = true;
  bool makePaddleSensorAndDestroyBall = false;
  bool toTheNextLevel = false;
  double accelerationRateForSpeed = 0.0;

  var jointDef = PrismaticJointDef();

  late int highScore;
  int scoreValue = 0;

  @override
  Future<void> onLoad() async {
    await _loadHighScore();
    await _initializeGame();
    FlameAudio.bgm.play('theme.ogg');
  }

  Future<void> _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;
  }

  Future<void> _saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  Future<void> _initializeGame() async {
    final paddingRatio = Vector2(0.0, 0.0);
    paddingRatio.x = 43 / 1033;
    paddingRatio.y = 44 / 1060;

    _scoreSize = Size(
      size.x,
      size.y * 0.05,
    );
    _scorePosition = Vector2(
        0,
        0
    );
    _score = Score(
      size: _scoreSize,
      position: _scorePosition,
      score: 0,
      highScore: highScore
    );
    await add(_score);

    _arenaSize = Size(
      size.x,
      size.y - _scoreSize.height,
    );
    _arenaPosition = Vector2(
        0,
        _scoreSize.height
    );
    _arena = Arena(
      size: _arenaSize,
      position: _arenaPosition,
      imageArenaPath: 'assets/images/arena.png',
      gifExitPath: 'assets/animations/exit.gif',
      imageExitPath: 'assets/images/exit.png',
    );
    await add(_arena);

    _brickWallSize = Size(
      _arenaSize.width * (1 - 2 * paddingRatio.x),
      _arenaSize.height * 255 / 1060,
    );
    _brickWallPosition = Vector2(
      _arenaSize.width * paddingRatio.x,
      _arenaPosition.y + _arenaSize.height * paddingRatio.y + _arenaSize.height * 135 / 1060,
    );
    _brickWall = BrickWall(
      position: _brickWallPosition,
      size: _brickWallSize,
      rows: 6,
      columns: 11,
    );
    await add(_brickWall);

    _deadZoneSize = Size(
        _arenaSize.width * (1 - 2 * paddingRatio.x),
        _arenaSize.height * (1 - paddingRatio.y - 940 / 1060)
    );
    _deadZonePosition = Vector2(
      _arenaSize.width / 2.0,
      _arenaPosition.y + _arenaSize.height - _deadZoneSize.height / 2.0,
    );
    _deadZone = DeadZone(
      size: _deadZoneSize,
      position: _deadZonePosition,
    );
    await add(_deadZone);

    _paddleSize = Size(
        _arenaSize.width * 135 / 1033,
        _arenaSize.height * 33 / 1060
    );
    _paddlePosition = Vector2(
      _arenaSize.width / 2.0,
      _arenaPosition.y + _arenaSize.height - _deadZoneSize.height - _paddleSize.height / 2.0,
    );
    _paddle = Paddle(
      size: _paddleSize,
      position: _paddlePosition,
      imagePath: 'assets/images/paddle/paddleOriginal.png',
    );
    await add(_paddle);

    _ballSize = 0.5 * _arenaSize.width * 27 / 1033;
    _ballPosition = Vector2(
      _arenaSize.width / 2.0,
      _arenaPosition.y + _arenaSize.height - _deadZoneSize.height - _paddleSize.height,
    );
    _balls = BallManager(
      radius: _ballSize,
      position: _ballPosition,
      imagePath: 'assets/images/ball.png',
    );
    await _balls.createBall();
    await add(_balls);

    _livesSize = Size(
      _arenaSize.width * (1 - 2 * paddingRatio.x),
      _arenaSize.height * 16 / 1060,
    );
    _livesPosition = Vector2(
      _arenaSize.width * paddingRatio.x,
      _arenaPosition.y + _arenaSize.height * paddingRatio.y + _arenaSize.height * 999 / 1060,
    );
    _lives = LifeManager(
      position: _livesPosition,
      size: _livesSize,
      imagePath: 'paddle/paddleLife.png',
    );
    await add(_lives);

    _bullets = BulletManager();
    await add(_bullets);

    gameState = GameState.ready;
    overlays.add('PreGame');
  }

  Future<void> applyBonus() async {
    if (bonusState != _previousBonusState) {
      switch (_previousBonusState) {
        case BonusState.blue:
          final paddleSize = Size(size.x * 135 / 1033, size.y * 33 / 1060);
          _paddle.updateBody(
            newSize: paddleSize,
            imagePath: 'assets/images/paddle/paddleOriginal.png',
            isSensor: false,
          );
          break;
        case BonusState.gray: break;
        case BonusState.green: break;
        case BonusState.lightBlue: break;
        case BonusState.orange:
          accelerationRateForSpeed = 0.5;
          break;
        case BonusState.pink: break;
        case BonusState.red:
          final paddleSize = Size(size.x * 135 / 1033, size.y * 33 / 1060);
          _paddle.updateBody(
              newSize: paddleSize,
              imagePath: 'assets/images/paddle/paddleOriginal.png',
              isSensor: false,
          );
          break;
        case BonusState.none: break;
      }

      switch (bonusState) {
        case BonusState.blue:
          final paddleSize = Size(size.x * 200 / 1033, size.y * 33 / 1060);
          _paddle.updateBody(
            newSize: paddleSize,
            imagePath: 'assets/images/paddle/paddleLong.png',
            isSensor: false,
          );
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
          _balls.balls.last.isVisible = true;
          await _balls.createBall(
            position: ballPosition,
            linearVelocity: (v * cos(alpha) - u * sin(alpha)),
          );
          _balls.balls.last.isVisible = true;
          break;
        case BonusState.orange:
          accelerationRateForSpeed = -0.5;
          break;
        case BonusState.pink: break;
        case BonusState.red:
          final paddleSize = Size(size.x * 135 / 1033, size.y * 33 / 1060);
          _paddle.updateBody(
            newSize: paddleSize,
            imagePath: 'assets/images/paddle/paddleWithLaser.png',
            isSensor: false,
          );
          break;
        case BonusState.none: break;
      }
      _previousBonusState = bonusState;
    } else {
      switch (bonusState) {
        case BonusState.blue: break;
        case BonusState.gray: break;
        case BonusState.green: break;
        case BonusState.lightBlue: break;
        case BonusState.orange: break;
        case BonusState.pink:
          if (_paddle.body.position.x - _paddle.size.width / 2 > size.x) {
            gameState = GameState.won;
          }
          if (makePaddleSensorAndDestroyBall) {
            final paddleSize = Size(size.x * 135 / 1033, size.y * 33 / 1060);
            _paddle.updateBody(
                newSize: paddleSize,
                imagePath: 'assets/images/paddle/paddleOriginal.png',
                isSensor: true,
            );
            updateScore(10000);
            _balls.balls.last.destroy = true;
            _balls.removeBall();
            _brickWall.resetOnlyBonuses();
            _paddle.body.linearVelocity = Vector2(5, 0);
            makePaddleSensorAndDestroyBall = false;
            toTheNextLevel = true;
          }
          break;
        case BonusState.red: break;
        case BonusState.none: break;
      }
    }
  }

  void updateScore(int value) {
    scoreValue += value;
    if (scoreValue > highScore) {
      highScore = scoreValue;
      _saveHighScore();
    }

    _score.updateScore(
      score: scoreValue,
      highScore: highScore
    );
  }

  void resetScore() {
    scoreValue = 0;
    _score.updateScore(
        score: scoreValue,
        highScore: highScore
    );
  }

  Future<void> resetGame() async {
    gameState = GameState.initializing;

    _paddle.reset();
    _balls.reset();
    await _brickWall.reset();
    _lives.reset();
    _bullets.reset();
    resetScore();

    isBonusesFall = true;
    accelerationRateForSpeed = 0.0;
    makePaddleSensorAndDestroyBall = false;
    toTheNextLevel = false;
    _arena.showExit = false;

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
          makePaddleSensorAndDestroyBall = false;
          toTheNextLevel = false;
          _arena.showExit = false;

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
            _balls.balls.last.body.angularVelocity = 0;
            isBallConnectedToThePaddle = false;
          }

          if (bonusState == BonusState.red) {
            _bullets.createBullets(
                arenaSize: _arenaSize,
                paddlePosition: _paddle.body.position,
                paddleSize: _paddleSize,
                imagePath: 'assets/images/bullet.png',
            );
          }
        }
        if (gameState == GameState.ready) {
          _paddle.isVisible = true;
          _balls.balls.last.isVisible = true;

          overlays.remove(overlays.activeOverlays.first);
          jointDef
            ..initialize(_paddle.body, _balls.balls.last.body, _paddle.body.position, Vector2(1, 0))
            ..enableLimit = true
            ..lowerTranslation = 0
            ..upperTranslation = 0;
          world.createJoint(PrismaticJoint(jointDef));
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
