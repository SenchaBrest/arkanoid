import 'dart:ui';
import 'package:flame/components.dart';



class LifeManager extends Component {
  List<Life> lives = [];
  final Vector2 position;
  final Size size;
  final String imagePath;

  LifeManager({
    required this.position,
    required this.size,
    required this.imagePath,
  }) {
    addLife();
    addLife();
  }

  late Vector2 lifeSize = Vector2(
    64 / 961 * size.width,
    size.height
  );

  void addLife() {
    late Vector2 lifePosition;

    if (lives.isEmpty) {
      lifePosition = position +
          Vector2(48 / 961 * size.width, 0);
    }
    else {
      lifePosition = position +
          Vector2(48 / 961 * size.width, 0) +
          Vector2(lives.length * (64 / 961 + 22 / 961) * size.width, 0);
    }

    final life = Life(position: lifePosition, size: lifeSize, imagePath: imagePath);
    add(life);
    lives.add(life);
  }

  void removeLife() {
    remove(lives.last);
    lives.removeLast();
  }

  bool isNotEmpty(){
    return lives.isNotEmpty ? true : false;
  }

  void reset() {
    while (lives.isNotEmpty) {
      removeLife();
    }
    addLife();
    addLife();
  }
}

class Life extends SpriteComponent with HasGameRef {
  final String imagePath;

  Life({required Vector2 position, required Vector2 size, required this.imagePath})
      : super(
    size: size,
    position: position,
  );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite(imagePath);
  }
}
