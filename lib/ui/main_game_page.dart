import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../forge2d_game_world.dart';
import 'overlay_builder.dart';


class MainGamePage extends StatefulWidget {
  const MainGamePage({super.key});

  @override
  MainGameState createState() => MainGameState();
}

class MainGameState extends State<MainGamePage> {
  final forge2dGameWorld = Forge2dGameWorld();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black87,
        margin: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 0,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double size = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth// * 1033 / 1060 // 950 * 1017
                : constraints.maxHeight;

            return Center(
              child: SizedBox(
                width: size,
                height: size,
                child: GameWidget(
                  game: forge2dGameWorld,
                  overlayBuilderMap: const {
                    'PreGame': OverlayBuilder.preGame,
                    // 'InGame': OverlayBuilder.inGame,
                    'PostGame': OverlayBuilder.postGame,
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
