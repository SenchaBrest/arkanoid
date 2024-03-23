import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/input.dart';

import 'components/arena.dart';
import 'components/ball.dart';
import 'components/brick_wall.dart';
import 'components/paddle.dart';
import 'components/dead_zone.dart';
import 'components/life.dart';


enum GameState {
  initializing,
  ready,
  running,
  paused,
  won,
  lost,
}

class Forge2dGameWorld extends Forge2DGame with HasDraggables, HasTappables {
  Forge2dGameWorld() : super(gravity: Vector2.zero(), zoom: 20);

  GameState gameState = GameState.initializing;

  late final Arena _arena;
  late final Ball _ball;
  late final BrickWall _brickWall;
  late final DeadZone _deadZone;
  late final Paddle _paddle;
  late final LifeManager lives;

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
      ground: _arena,
      position: paddlePosition,
    );
    await add(_paddle);

    final ballPosition = Vector2(
        size.x / 2.0,
        size.y - deadZoneSize.height - paddleSize.height,
    );
    _ball = Ball(
      radius: 0.5 * size.x * 27 / 1033,
      position: ballPosition,
    );
    await add(_ball);

    final lifeManagerSize = Size(
      size.x * (1 - 2 * paddingRatio.x),
      size.y * 16 / 1060,
    );
    final lifeManagerPosition = Vector2(
      size.x * paddingRatio.x,
      size.y * paddingRatio.y + size.y * 999 / 1060,
    );

    lives = LifeManager(
      position: lifeManagerPosition,
      size: lifeManagerSize,
    );
    lives.addLife();
    lives.addLife();
    await add(lives);

    gameState = GameState.ready;
    overlays.add('PreGame');
  }

  Future<void> resetGame() async {
    gameState = GameState.initializing;

    _ball.reset();
    _paddle.reset();
    await _brickWall.reset();

    gameState = GameState.ready;

    overlays.remove(overlays.activeOverlays.first);
    overlays.add('PreGame');

    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameState == GameState.lost || gameState == GameState.won) {
      pauseEngine();
    }
  }

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    if (gameState == GameState.ready) {
      overlays.remove('PreGame');
      _ball.body.applyLinearImpulse(Vector2(-10.0, -10.0));
      gameState = GameState.running;
    }
    super.onTapDown(pointerId, info);

    if (gameState == GameState.lost || gameState == GameState.won) {
      pauseEngine();
      overlays.add('PostGame');
    }
  }
}
