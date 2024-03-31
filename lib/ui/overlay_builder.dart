import 'package:flutter/material.dart';
import '../forge2d_game_world.dart';

class OverlayBuilder {
  OverlayBuilder._();

  static Widget preGame(BuildContext context, Forge2dGameWorld game) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = game.size.x * (1033 - 2 * 43) / 1033;
        final fontSize = width * 0.5;

        return PreGameOverlay(fontSize: fontSize);
      },
    );
  }

  static Widget postGame(BuildContext context, Forge2dGameWorld game) {
    assert(game.gameState == GameState.lost || game.gameState == GameState.won);

    final message = game.gameState == GameState.won ? 'Winner!' : 'Game Over';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final fontSize = width * 0.1;

        return PostGameOverlay(
          message: message,
          game: game,
          fontSize: fontSize,
        );
      },
    );
  }
}

class PreGameOverlay extends StatelessWidget {
  final double fontSize;

  const PreGameOverlay({Key? key, required this.fontSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tap space to unlock the game',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontFamily: 'PressStart2P',
        ),
      ),
    );
  }
}

class PostGameOverlay extends StatelessWidget {
  final String message;
  final Forge2dGameWorld game;
  final double fontSize;

  const PostGameOverlay({
    Key? key,
    required this.message,
    required this.game,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontFamily: 'PressStart2P',
            ),
          ),
          SizedBox(height: fontSize * 0.5),
          _resetButton(context, game),
        ],
      ),
    );
  }

  Widget _resetButton(BuildContext context, Forge2dGameWorld game) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: Colors.blue,
        ),
      ),
      onPressed: () => game.resetGame(),
      icon: const Icon(Icons.restart_alt_outlined),
      label: const Text('Replay'),
    );
  }
}


