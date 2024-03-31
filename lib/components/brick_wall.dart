import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../forge2d_game_world.dart';

import 'brick.dart';
import 'bonus.dart';

class BrickWall extends Component with HasGameRef<Forge2dGameWorld> {
  final Vector2 position;
  final Size? size;
  final int rows;
  final int columns;
  final double gap;

  BrickWall({
    Vector2? position,
    this.size,
    int? rows,
    int? columns,
    double? gap,
  })  : position = position ?? Vector2.zero(),
        rows = rows ?? 1,
        columns = columns ?? 1,
        gap = gap ?? 0.1;

  @override
  Future<void> onLoad() async {
    await _buildWall();
  }

  @override
  void update(double dt) {
    for (final child in [...children]) {
      if (child is Brick && child.destroy) {
        for (final fixture in [...child.body.fixtures]) {
          child.body.destroyFixture(fixture);
        }
        gameRef.world.destroyBody(child.body);
        remove(child);
      }
      if (child is Bonus && child.destroy) {
        for (final fixture in [...child.body.fixtures]) {
          child.body.destroyFixture(fixture);
        }
        gameRef.world.destroyBody(child.body);
        remove(child);
      }
    }

    bool foundBrick = false;

    for (final child in [...children]) {
      if (child is Brick) {
        foundBrick = true;
        break;
      }
    }

    if (!foundBrick) {
      gameRef.gameState = GameState.won;
    }

    super.update(dt);
  }

  Future<void> _buildWall() async {
    final wallSize = size!;

    final brickSize = Size(
      ((wallSize.width - gap * 2.0) - (columns - 1) * gap) / columns,
      (wallSize.height - (rows - 1) * gap) / rows,
    );

    var brickPosition = Vector2(
      brickSize.width / 2.0 + position.x + gap,
      brickSize.height / 2.0 + position.y,
    );

    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < columns; j++) {
        List<BrickColor> brickColors = BrickColor.values;
        await add(Brick(
          size: brickSize,
          position: brickPosition,
          brickColor: brickColors[i],
        ));
        brickPosition += Vector2(brickSize.width + gap, 0.0);
      }
      brickPosition += Vector2(
        (brickSize.width / 2.0 + gap) - brickPosition.x + position.x,
        brickSize.height + gap,
      );
    }
  }

  Future<void> reset() async {
    removeAll(children);
    await _buildWall();
  }

  Future<void> resetOnlyBonuses() async {
    for (final child in [...children]) {
      if (child is Bonus) {
        for (final fixture in [...child.body.fixtures]) {
          child.body.destroyFixture(fixture);
        }
        gameRef.world.destroyBody(child.body);
        remove(child);
      }
    }
  }
}
