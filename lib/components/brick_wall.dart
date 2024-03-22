// Copyright (c) 2022 Razeware LLC

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
// distribute, sublicense, create a derivative work, and/or sell copies of the
// Software in any work that is designed, intended, or marketed for pedagogical
// or instructional purposes related to programming, coding, application
// development, or information technology.  Permission for such use, copying,
// modification, merger, publication, distribution, sublicensing, creation of
// derivative works, or sale is expressly withheld.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../forge2d_game_world.dart';
import 'brick.dart';

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

  late final List<Color> _colors;


  @override
  Future<void> onLoad() async {
    _colors = _colorSet(rows);
    await _buildWall();
  }

  @override
  void update(double dt) {
    // Check for bricks in the wall that have been flagged for removal.
    // Note: this is a destructive process so iterate over a copy of
    // the elements and not the actual list of children and fixtures.
    //
    for (final child in [...children]) {
      if (child is Brick && child.destroy) {
        for (final fixture in [...child.body.fixtures]) {
          child.body.destroyFixture(fixture);
        }
        gameRef.world.destroyBody(child.body);
        remove(child);
      }
    }

    if (children.isEmpty) {
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
        await add(Brick(
          size: brickSize,
          position: brickPosition,
          color: _colors[i],
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

  // Generate a set of colors for the bricks that span a range of colors.
  // This color generator creates a set of colors spaced across the
  // color spectrum.
  static const transparency = 1.0;
  static const saturation = 0.85;
  static const lightness = 0.5;

  List<Color> _colorSet(int count) => List<Color>.generate(
    count,
        (int index) => HSLColor.fromAHSL(
      transparency,
      index / count * 360.0,
      saturation,
      lightness,
    ).toColor(),
    growable: false,
  );
}
